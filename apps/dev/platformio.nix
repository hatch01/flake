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
      arduino-ide
      (python3.withPackages (ps: with python3Packages; [pyserial]))
    ];
    services.udev.packages = [
      pkgs.platformio-core
      pkgs.openocd
    ];
  };
}
