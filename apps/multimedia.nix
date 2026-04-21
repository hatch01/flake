{
  pkgs,
  config,
  lib,
  username,
  inputs,
  ...
}:
let
  inherit (lib) optionals mkEnableOption mkIf;
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

  config =
    with config;
    {
      # if we have editing tools, it is likely we also want to read multimedia
      multimedia.enable = mkIf multimedia.editing.enable true;

      environment.systemPackages =
        with pkgs;
        [ ]
        ++ optionals multimedia.enable [
          # reading
          ffmpeg-full
          vlc
          spotify
          yt-dlp
        ]
        ++ optionals multimedia.editing.enable [
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
    // mkIf multimedia.audio.enable (
      let
        # Live audio utilities
        pw-metadata = lib.getExe' pkgs.pipewire "pw-metadata";
        systemctl = lib.getExe' pkgs.systemd "systemctl";
        balooctl = lib.getExe' pkgs.kdePackages.baloo "balooctl6";

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

          # --- PipeWire : forcer 48kHz / 64 samples ---
          echo ""
          echo "🔧 Réglage PipeWire basse latence (48kHz / 64 samples)..."
          ${pw-metadata} -n settings 0 clock.force-rate 48000
          ${pw-metadata} -n settings 0 clock.force-quantum 64
          echo "  ✅ clock.force-rate  = 48000"
          echo "  ✅ clock.force-quantum = 64  (0.67ms buffer)"

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
          echo "🎚️  Configuration active :"
          ${pw-metadata} -n settings 2>/dev/null | grep -E "clock\.(force|rate|quantum)" | sed 's/^/  /'
          echo ""
          echo "💡 Lance Ardour avec : PIPEWIRE_LATENCY=\"64/48000\" ardour"
          echo "💡 Fin de session : live-stop"
          echo "⏸️  Appuyez sur Entrée pour fermer la console..."
          read -r
        '';

        # ─── Script : fin de session live ──────────────────────────────────────────
        liveStopScript = pkgs.writeShellScriptBin "live-stop" ''
          set -euo pipefail

          echo "🔄 === FIN DE SESSION LIVE ==="
          echo ""

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

        services.pipewire = {
          # Global low-latency defaults for native JACK clients
          extraConfig.pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000; # Fixed rate avoids resampling latency
              "default.clock.quantum" = 128; # ~5ms latency at 48kHz
              "default.clock.min-quantum" = 64; # ~2.5ms latency at 48kHz
              "default.clock.max-quantum" = 512;
            };
          };

          # Crucial: Match low-latency for PulseAudio clients (browsers, Steam/Rocksmith)
          extraConfig.pipewire-pulse."92-low-latency" = {
            "pulse.properties" = {
              "pulse.min.req" = "64/48000"; # Start with 64, not 32, for stability
              "pulse.default.req" = "64/48000";
              "pulse.max.req" = "128/48000";
            };
          };
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
        ];
      }
    );
}
