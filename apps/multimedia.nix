{
  pkgs,
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib) optionals mkEnableOption mkIf;
in
{
  options = {
    multimedia.enable = mkEnableOption "Enable multimedia reading packages";
    multimedia.audio.enable = mkEnableOption "Enable multimedia audio packages";
    multimedia.editing.enable = mkEnableOption "Enable multimedia editing packages";
  };

  config = with config; {
    # if we have editing tools, it is likely we also want to read multimedia
    multimedia.enable = mkIf multimedia.editing.enable true;

    # Set memory lock limit for the 'audio' group
    security.pam.loginLimits = mkIf multimedia.audio.enable [
      {
        domain = "@audio";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
    ];

    users.users.${username} = mkIf multimedia.audio.enable {
      extraGroups = [ "audio" ];
    };

    environment.systemPackages =
      with pkgs;
      [ ]
      ++ optionals multimedia.enable [
        # reading
        ffmpeg-full
        vlc
        spotify
        yt-dlp
        vdhcoapp
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
      ]
      ++ optionals multimedia.audio.enable [
        ardour
        hydrogen
        drumgizmo
        calf
        qsynth
        fluidsynth
        carla
        qjackctl
        qpwgraph
        helvum
        coppwr
        musescore
      ];
  };
}
