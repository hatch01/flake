{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    vesktop.enable = mkEnableOption "Enable social apps";
  };

  config = mkIf config.vesktop.enable {
    environment.systemPackages = with pkgs; [
      vesktop
    ];
    hm = {
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
    };
  };
}
