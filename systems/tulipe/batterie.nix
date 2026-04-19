{
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}:
let
  alesis-midi-converter =
    lib.getExe
      inputs.alesis_midi_converter.packages.${system}.alesis-midi-converter;

  # Live audio utilities
  pw-metadata = lib.getExe' pkgs.pipewire "pw-metadata";
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  balooctl = lib.getExe' pkgs.kdePackages.baloo "balooctl";
  systemd-inhibit = lib.getExe' pkgs.systemd "systemd-inhibit";

  # ─── Timers à stopper avant le live ────────────────────────────────────────
  liveBlockedSystemTimers = [
    "nh-clean.timer"
    "nix-gc.timer"
    "nix-optimise.timer"
    "fstrim.timer"
  ];
  liveBlockedSystemServices = [
    "comin.service"
  ];

  # ─── Script : démarrage mode live ──────────────────────────────────────────
  liveStartScript = pkgs.writeShellScriptBin "live-start" ''
    set -euo pipefail

    echo "🎛️  === MODE LIVE AUDIO ==="
    echo ""

    # --- Inhibit sleep/idle ---
    echo "🔒 Activation du verrou anti-sommeil/idle..."
    ${systemd-inhibit} --what=sleep:idle --why="Live audio session in progress" --mode=block sleep 1000000 &
    echo $! > /tmp/live-inhibit.pid
    echo "  ✅ Inhibit PID: $(cat /tmp/live-inhibit.pid)"
    echo ""

    # --- Timers système ---
    echo "⏸️  Arrêt des timers système..."
    ${lib.concatMapStringsSep "\n" (t: ''
      if ${systemctl} is-active --quiet "${t}" 2>/dev/null; then
        sudo ${systemctl} stop "${t}"
        echo "  ✅ ${t}"
      else
        echo "  ⏭️  ${t} (déjà inactif)"
      fi
    '') liveBlockedSystemTimers}

    # --- Services auto (comin, etc.) ---
    echo ""
    echo "⏸️  Arrêt des services de mise à jour..."
    ${lib.concatMapStringsSep "\n" (s: ''
      if ${systemctl} is-active --quiet "${s}" 2>/dev/null; then
        sudo ${systemctl} stop "${s}"
        echo "  ✅ ${s}"
      else
        echo "  ⏭️  ${s} (déjà inactif)"
      fi
    '') liveBlockedSystemServices}

    # --- Baloo (indexeur KDE) ---
    echo ""
    echo "⏸️  Suspension de Baloo..."
    ${balooctl} suspend && echo "  ✅ Baloo suspendu" || echo "  ⚠️  Erreur balooctl"

    # --- PipeWire : forcer 96kHz / 64 samples ---
    echo ""
    echo "🔧 Réglage PipeWire basse latence (96kHz / 64 samples)..."
    ${pw-metadata} -n settings 0 clock.force-rate 96000
    ${pw-metadata} -n settings 0 clock.force-quantum 64
    echo "  ✅ clock.force-rate  = 96000"
    echo "  ✅ clock.force-quantum = 64  (0.67ms buffer)"

    # --- Vérification RT ---
    echo ""
    echo "🔍 Vérification temps réel..."
    RT_OK=true

    # Kernel RT ?
    if uname -r | grep -qiE "rt|preempt"; then
      echo "  ✅ Kernel PREEMPT_RT : $(uname -r)"
    else
      echo "  ⚠️  Kernel non-RT détecté : $(uname -r)"
      RT_OK=false
    fi

    # CPU governor ?
    GOVERNORS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u)
    if echo "$GOVERNORS" | grep -q "^performance$"; then
      echo "  ✅ CPU governor : performance"
    else
      echo "  ⚠️  CPU governor : $GOVERNORS (attendu: performance)"
      RT_OK=false
    fi

    # Swappiness ?
    SWAP=$(cat /proc/sys/vm/swappiness)
    if [ "$SWAP" -le 10 ]; then
      echo "  ✅ Swappiness : $SWAP"
    else
      echo "  ⚠️  Swappiness : $SWAP (attendu: ≤10)"
    fi

    # rtkit actif ?
    if ${systemctl} is-active --quiet rtkit-daemon; then
      echo "  ✅ rtkit-daemon actif"
    else
      echo "  ❌ rtkit-daemon inactif !"
      RT_OK=false
    fi

    # PipeWire RT (data-loop.0) ?
    PW_PID=$(pgrep -f "pipewire$" 2>/dev/null | head -1 || true)
    if [ -n "$PW_PID" ]; then
      DL_TID=$(cat /proc/"$PW_PID"/task/*/status 2>/dev/null \
        | awk '/^Name:.*data-loop/{found=1} found && /^Pid:/{print $2; exit}')
      if [ -n "$DL_TID" ]; then
        SCHED=$(chrt -p "$DL_TID" 2>/dev/null | grep "stratégie\|policy" | grep -o "SCHED_[A-Z]*" | head -1)
        if echo "$SCHED" | grep -q "FIFO"; then
          PRIO=$(chrt -p "$DL_TID" 2>/dev/null | grep "priorité\|priority" | grep -o "[0-9]*$")
          echo "  ✅ PipeWire data-loop : $SCHED prio $PRIO"
        else
          echo "  ⚠️  PipeWire data-loop : $SCHED (pas FIFO — rtkit n'a peut-être pas encore promu)"
          RT_OK=false
        fi
      fi
    fi

    echo ""
    if [ "$RT_OK" = true ]; then
      echo "✅ Système prêt pour le live !"
    else
      echo "⚠️  Certains checks ont échoué — vérifie avant de jouer."
    fi

    echo ""
    echo "🎚️  Configuration active :"
    ${pw-metadata} -n settings 2>/dev/null | grep -E "clock\.(force|rate|quantum)" | sed 's/^/  /'
    echo ""
    echo "💡 Lance Ardour avec : PIPEWIRE_LATENCY=\"64/96000\" ardour"
    echo "💡 Fin de session : live-stop"
  '';

  # ─── Script : fin de session live ──────────────────────────────────────────
  liveStopScript = pkgs.writeShellScriptBin "live-stop" ''
    set -euo pipefail

    echo "🔄 === FIN DE SESSION LIVE ==="
    echo ""

    # --- Kill inhibit process ---
    if [ -f /tmp/live-inhibit.pid ]; then
      INHIBIT_PID=$(cat /tmp/live-inhibit.pid)
      kill "$INHIBIT_PID" 2>/dev/null || true
      rm /tmp/live-inhibit.pid
      echo "🔓 Verrou anti-sommeil/idle levé"
    fi


    # --- Relancer les timers ---
    echo "▶️  Relance des timers système..."
    ${lib.concatMapStringsSep "\n" (t: ''
      sudo ${systemctl} start "${t}" 2>/dev/null && echo "  ✅ ${t}" || echo "  ⚠️  ${t} (échec)"
    '') liveBlockedSystemTimers}

    echo ""
    echo "▶️  Relance des services..."
    ${lib.concatMapStringsSep "\n" (s: ''
      sudo ${systemctl} start "${s}" 2>/dev/null && echo "  ✅ ${s}" || echo "  ⏭️  ${s} (non trouvé ou déjà actif)"
    '') liveBlockedSystemServices}

    # --- Baloo ---
    echo ""
    echo "▶️  Reprise de Baloo..."
    ${balooctl} resume && echo "  ✅ Baloo repris" || echo "  ⚠️  Erreur balooctl"

    # --- PipeWire : retour aux réglages normaux ---
    echo ""
    echo "🔧 Retour aux réglages PipeWire normaux..."
    ${pw-metadata} -n settings 0 clock.force-rate 0
    ${pw-metadata} -n settings 0 clock.force-quantum 0
    echo "  ✅ Quantum dynamique rétabli"
    echo "  ✅ Sample rate dynamique rétabli"

    echo ""
    echo "✅ Système revenu en mode normal."
  '';

  # ─── Desktop items ──────────────────────────────────────────────────────────
  batterieDesktopItem = pkgs.makeDesktopItem {
    name = "batterie-setup";
    desktopName = "Batterie Setup";
    comment = "Lance le setup Ardour/MIDI pour la batterie";
    exec = "${pkgs.systemd}/bin/systemctl --user restart batterie-setup.service";
    icon = "media-playback-start";
    terminal = false;
    categories = [
      "AudioVideo"
      "Music"
    ];
  };

  liveStartDesktopItem = pkgs.makeDesktopItem {
    name = "live-start";
    desktopName = "🎛️ Mode Live Audio";
    comment = "Prépare le système pour une session live (basse latence)";
    exec = "${liveStartScript}/bin/live-start";
    icon = "audio-headphones";
    terminal = true;
    categories = [
      "AudioVideo"
      "Music"
    ];
  };

  liveStopDesktopItem = pkgs.makeDesktopItem {
    name = "live-stop";
    desktopName = "🔄 Fin Session Live";
    comment = "Remet le système en mode normal";
    exec = "${liveStopScript}/bin/live-stop";
    icon = "media-playback-stop";
    terminal = true;
    categories = [
      "AudioVideo"
      "Music"
    ];
  };

  # ─── Setup batterie (script simplifié, délègue à alesis-midi-converter) ────
  setupScript = pkgs.writeShellScript "batterie-setup" ''
    set -uexo pipefail
    echo "Batterie setup: Starting..." >&2
    ${alesis-midi-converter} &
    echo "Alesis MIDI converter started" >&2
  '';

in
{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  # ─── Packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = [
    batterieDesktopItem
    liveStartDesktopItem
    liveStopDesktopItem
    liveStartScript
    liveStopScript
  ];

  # ─── Musnix : kernel RT + optimisations audio ───────────────────────────────
  musnix.enable = true;
  musnix.soundcardPciId = "07:00.6";
  musnix.kernel.packages = pkgs.linuxPackages_latest;
  musnix.kernel.realtime = true;
  # musnix.rtirq.enable = true;  # à activer si xruns persistants
  security.rtkit.enable = true;

  # ─── udev : détection de la batterie Alesis ─────────────────────────────────
  services.udev.extraRules = ''
    ATTR{idVendor}=="13b2", ATTR{idProduct}=="009f", ACTION=="add",    RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-trigger@${username}.service"
    ENV{ID_VENDOR_ID}=="13b2", ENV{ID_MODEL_ID}=="009f", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-cleanup@${username}.service"
  '';

  # ─── Services système pour bridge udev → user ───────────────────────────────
  systemd.services."batterie-udev-trigger@" = {
    description = "Trigger batterie-setup for user %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash %i -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) ${pkgs.systemd}/bin/systemctl --user restart batterie-setup.service'";
    };
  };

  systemd.services."batterie-udev-cleanup@" = {
    description = "Stop batterie-setup for user %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash %i -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) ${pkgs.systemd}/bin/systemctl --user stop batterie-setup.service'";
    };
  };

  # ─── Service user : batterie-setup ──────────────────────────────────────────
  systemd.user.services.batterie-setup = {
    description = "Setup Ardour and MIDI for Alesis drum kit";
    serviceConfig = {
      Type = "forking";
      ExecStart = setupScript;
      Restart = "no";
      RemainAfterExit = true;
    };
  };
}
