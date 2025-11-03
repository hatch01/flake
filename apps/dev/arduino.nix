{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
in
{
  options = {
    arduino.enable = mkEnableOption "arduino";
  };

  config = mkIf config.arduino.enable {
    environment.systemPackages =
      with pkgs;
      [
        platformio
        platformio-core
        avrdude
        (python3.withPackages (ps: with python3Packages; [ pyserial ]))
        kicad
      ]
      ++ optionals (system == "x86_64-linux") [ pkgs.arduino-ide ];
    services.udev.packages = [
      pkgs.platformio-core
      pkgs.openocd
    ];
  };
}
