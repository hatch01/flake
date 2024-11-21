{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionals;
in {
  options = {
    platformio.enable = mkEnableOption "platformio";
  };

  config = mkIf config.platformio.enable {
    environment.systemPackages = with pkgs;
      [
        platformio
        platformio-core
        avrdude
        (python3.withPackages (ps: with python3Packages; [pyserial]))
      ]
      ++ optionals (pkgs.system == "x86_64-linux") [pkgs.arduino-ide];
    services.udev.packages = [
      pkgs.platformio-core
      pkgs.openocd
    ];
  };
}
