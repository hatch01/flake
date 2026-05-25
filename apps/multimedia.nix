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
    (mkIf config.multimedia.audio.enable ({
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
      # musnix.rtirq.enable = true;
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
        (ardour.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            (fetchpatch {
              # enable midi control for plugin bypasses
              url = "https://github.com/Ardour/ardour/pull/1111.patch";
              hash = "sha256-UL1b9PagNv3DcJaqxaF4GZZ85bLhsT77W3lB1bfefD0=";
            })
          ];
        }))
        hydrogen
        drumgizmo
        alsa-utils
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
    }))
  ];
}
