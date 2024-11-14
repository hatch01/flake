{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption optionals mkIf;
in {
  options = {
    platformio.enable = mkEnableOption "platformio";
  };

  config = mkIf config.platformio.enable {
    environment.systemPackages = with pkgs; [
      platformio
      avrdude
    ];
    services.udev.packages = [
      pkgs.platformio-core
      pkgs.openocd
    ];
  };
}
