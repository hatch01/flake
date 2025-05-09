{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault mkIf;
in {
  options = {
    social.enable = mkEnableOption "Enable social apps";
  };

  imports = [
    ./vesktop
  ];

  config = {
    # enable vesktop if social apps are enabled
    # but be able to disable it
    vesktop.enable = mkDefault config.social.enable;
    environment.systemPackages = with pkgs;
      mkIf config.social.enable [
        signal-desktop
        zapzap
        element-desktop
      ];
  };
}
