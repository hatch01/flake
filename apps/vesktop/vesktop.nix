{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    vesktop
  ];
  home.file.".config/vesktop/settings" = {
    source = ./settings;
    recursive = true;
    force = true;
  };
  home.file.".config/vesktop/themes" = {
    source = ./themes;
    recursive = true;
    force = true;
  };
}
