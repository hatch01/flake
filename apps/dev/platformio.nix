{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    platformio.enable = mkEnableOption "platformio";
  };

  config = mkIf config.platformio.enable {
    environment.systemPackages = with pkgs; [
      platformio
      platformio-core
      avrdude
      python312Packages.pyserial
      arduino-ide
    ];
    services.udev.packages = [
      pkgs.platformio-core
      pkgs.openocd
    ];
  };
}
