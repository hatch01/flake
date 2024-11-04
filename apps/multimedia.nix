{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) optionals mkEnableOption mkIf;
in {
  options = {
    multimedia.enable = mkEnableOption "Enable multimedia reading packages";
    multimedia.editing.enable = mkEnableOption "Enable multimedia editing packages";
  };

  config = with config; {
    # if we have editing tools, it is likely we also want to read multimedia
    multimedia.enable = mkIf multimedia.editing.enable true;
    environment.systemPackages = with pkgs;
      []
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
        gimp
        #blender
        imagemagick
        kdePackages.kdenlive
        kdePackages.kcolorchooser
        obs-studio
        inkscape-with-extensions
      ];
  };
}
