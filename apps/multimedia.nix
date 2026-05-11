{
  pkgs,
  config,
  lib,
  username,
  inputs,
  ...
}:
let
  inherit (lib)
    optionals
    mkEnableOption
    mkIf
    mkMerge
    ;

in
{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  options = {
    multimedia.enable = mkEnableOption "Enable multimedia reading packages";
    multimedia.audio.enable = mkEnableOption "Enable multimedia audio packages";
    multimedia.editing.enable = mkEnableOption "Enable multimedia editing packages";
  };

  config = mkMerge [
    {
      # if we have editing tools, it is likely we also want to read multimedia
      multimedia.enable = mkIf config.multimedia.editing.enable true;

      environment.systemPackages =
        with pkgs;
        [ ]
        ++ optionals config.multimedia.enable [
          # reading
          ffmpeg-full
          vlc
          spotify
          yt-dlp
        ]
        ++ optionals config.multimedia.editing.enable [
          # editing
          gimp3
          #blender
          imagemagick
          kdePackages.kdenlive
          kdePackages.kcolorchooser
          obs-studio
          inkscape-with-extensions
        ];
    }
    (mkIf config.multimedia.audio.enable (
      let
        # Live audio utilities
        systemctl = lib.getExe' pkgs.systemd "systemctl";
        balooctl = lib.getExe' pkgs.kdePackages.baloo "balooctl6";
        rfkill = lib.getExe' pkgs.util-linux "rfkill";

        # ─── Services à bloquer en mode live ──────────────────────────────────────
        # Organize services by category for clarity
        liveBlockedSystemTimers = [
          "nh-clean.timer"
          "nix-optimise.timer"
          "fstrim.timer"
        ];
        liveBlockedSystemServices = [
          "comin.service"
          "nix-daemon.service"
          "avahi-daemon.service"
          "NetworkManager.service"
          "docker.socket"
          "docker.service"
          "tailscaled.service"
          "beszel-agent.service"
          "ollama.service"
          "cups.socket"
          "cups.service"
          "spice-vdagentd.service"
          "wpa_supplicant.service"
          "dnsproxy.service"
          "geoclue.service"
          "ModemManager.service"
          "nscd.service"
        ];
        liveBlockedUserServices = [
          "pipewire.socket"
          "pipewire.service"
          "pipewire-pulse.socket"
          "pipewire-pulse.service"
          "wireplumber.service"
          "speech-dispatcher.socket"
          "speech-dispatcher.service"
        ];

        # Helper function to generate systemctl commands for service management
        manageServices =
          action: services:
          lib.concatMapStringsSep "\n" (s: ''
            sudo ${systemctl} ${action} "${s}" 2>/dev/null && echo "  ✅ ${s}" || echo "  ⚠️  ${s}"
          '') services;

        manageUserServices =
          action: services:
          lib.concatMapStringsSep "\n" (s: ''
            ${systemctl} --user ${action} "${s}" 2>/dev/null && echo "  ✅ ${s}" || echo "  ⚠️  ${s}"
          '') services;

        # ─── Script : démarrage mode live ──────────────────────────────────────────
        liveStartScript = pkgs.writeShellScriptBin "live-start" ''
          set -euo pipefail

          echo "🎛️  === MODE LIVE AUDIO ==="
          echo ""

          # podman
          podman stop -a || true
          sudo podman stop -a || true

          # kill
          sudo pkill openrgb || true
          pkill nextcloud || true

          # disable bluetooth/wifi
          ${rfkill} block bluetooth
          sudo systemctl stop bluetooth.service
          sudo pkill bluetoothd
          ${rfkill} block wifi

          # --- Timers système ---
          echo "⏸️  Arrêt des timers système..."
          ${manageServices "stop" liveBlockedSystemTimers}

          # --- Services auto (comin, etc.) ---
          echo ""
          echo "⏸️  Arrêt des services système..."
          ${systemctl} stop nix-gc.service # Stop appart to avoid starting at the end of the session
          ${manageServices "stop" liveBlockedSystemServices}

          # --- Baloo (indexeur KDE) ---
          echo ""
          echo "⏸️  Suspension de Baloo..."
          ${balooctl} suspend && echo "  ✅ Baloo suspendu" || echo "  ⚠️  Erreur balooctl"

          # --- PipeWire & User Services ---
          echo ""
          echo "⏸️  Arrêt des services utilisateur..."
          ${manageUserServices "stop" liveBlockedUserServices}

          # --- Vérification RT ---
          echo ""
          echo "🔍 Vérification temps réel..."
          RT_OK=true

          # Kernel RT ?
          if uname -a | grep -qiE "rt|preempt"; then
            echo "  ✅ Kernel PREEMPT_RT : $(uname -a)"
          else
            echo "  ⚠️  Kernel non-RT détecté : $(uname -a)"
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

          echo ""
          if [ "$RT_OK" = true ]; then
            echo "✅ Système prêt pour le live !"
          else
            echo "⚠️  Certains checks ont échoué — vérifie avant de jouer."
          fi

          echo ""
          echo "💡 Fin de session : live-stop"
          echo "⏸️  Appuyez sur Entrée pour fermer la console..."
          read -r
        '';

        # ─── Script : fin de session live ──────────────────────────────────────────
        liveStopScript = pkgs.writeShellScriptBin "live-stop" ''
          set -euo pipefail

          echo "🔄 === FIN DE SESSION LIVE ==="
          echo ""

          # unlock wifi/bluetooth
          ${rfkill} unblock bluetooth
          ${rfkill} unblock wifi
          sudo ${systemctl} start bluetooth.service
          sudo systemctl restart NetworkManager.service

          # --- Relancer les timers ---
          echo "▶️  Relance des timers système..."
          ${manageServices "start" liveBlockedSystemTimers}

          echo ""
          echo "▶️  Relance des services..."
          ${manageServices "start" liveBlockedSystemServices}

          # --- Baloo ---
          echo ""
          echo "▶️  Reprise de Baloo..."
          ${balooctl} resume && echo "  ✅ Baloo repris" || echo "  ⚠️  Erreur balooctl"

          # --- PipeWire & User Services : retour aux réglages normaux ---
          echo ""
          echo "▶️  Relance des services utilisateur..."
          ${manageUserServices "start" liveBlockedUserServices}

          echo ""
          echo "✅ Système revenu en mode normal."
          echo "⏸️  Appuyez sur Entrée pour fermer la console..."
          read -r
        '';

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

      in
      {
        security.pam.loginLimits = [
          {
            domain = "@audio";
            item = "memlock";
            type = "-";
            value = "unlimited";
          }
          {
            domain = "@audio";
            item = "rtprio";
            type = "-";
            value = "95";
          }
        ];
        users.users.${username} = {
          extraGroups = [ "audio" ];
        };

        boot.kernelParams = [
          "threadirqs"
          "preempt=full" # Optional: add if experiencing Xruns
          "amd_pstate=passive" # Zen 4/5: passive + performance governor = stable freq
          # For Intel or older AMD: remove amd_pstate or use "intel_pstate=active"
          "usbcore.autosuspend=-1" # Prevent USB audio interface sleep
        ];

        # ─── Musnix : kernel RT + optimisations audio ───────────────────────────────
        musnix.enable = true;
        musnix.soundcardPciId = "07:00.6";
        musnix.kernel.packages = pkgs.linuxPackages_latest;
        musnix.kernel.realtime = true;
        # musnix.rtirq.enable = true;  # à activer si xruns persistants
        security.rtkit.enable = true;

        environment.sessionVariables =
          let
            makePluginPath =
              format:
              (pkgs.lib.makeSearchPath format [
                "/run/current-system/sw/lib"
                "${config.users.users.${username}.home}/.nix-profile/lib"
              ])
              + ":$HOME/.${format}";
          in
          {
            LV2_PATH = makePluginPath "lv2";
            VST3_PATH = makePluginPath "vst3";
            CLAP_PATH = makePluginPath "clap";
          };

        environment.systemPackages = with pkgs; [
          liveStartDesktopItem
          liveStopDesktopItem
          liveStartScript
          liveStopScript
          ardour
          hydrogen
          drumgizmo
          lsp-plugins
          qsynth
          fluidsynth
          carla
          qjackctl
          qpwgraph
          crosspipe
          coppwr
          musescore
          demucs-rs
          surge-xt
          guitarix
          guitarix-vst
          zlequalizer
          zlcompressor
          zlsplitter
          dragonfly-reverb
          neural-amp-modeler-lv2
          kapitonov-plugins-pack
          meters-lv2
          rakarrack
          x42-avldrums
          x42-plugins
        ];
      }
    ))
  ];
}
