{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # editing
    gimp
    blender
    imagemagick
    kdePackages.kdenlive
    kdePackages.kcolorchooser
    obs-studio
    inkscape-with-extensions

    # reading
    ffmpeg-full
    vlc
    spotify
    yt-dlp
    config.nur.repos.milahu.vdhcoapp
  ];
}
