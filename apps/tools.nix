{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    basic-tools.enable = mkEnableOption "basic-tools";
  };

  config = mkIf config.basic-tools.enable {
    environment.systemPackages = with pkgs; [
      localsend
      minder
      kshutdown
      textpieces
      kdePackages.filelight
      (kdePackages.skanpage.override {
        tesseractLanguages = [
          "eng"
          "fra"
        ];
      })

      zap # cybersecurity website test

      #math
      kalker
      geogebra6
      octaveFull
    ];
  };
}
