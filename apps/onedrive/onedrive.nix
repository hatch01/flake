{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [onedrive];
  home.file.".config/onedrive/config" = {
    source = ./config;
    force = true;
  };
}
