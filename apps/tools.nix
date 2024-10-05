{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    basic-tools.enable = mkEnableOption "basic-tools";
  };

  config = {
    environment.systemPackages = with pkgs;
      mkIf config.basic-tools.enable [
        krename
        localsend
        minder
        kshutdown
        textpieces
        kdePackages.filelight
        (kdePackages.skanpage.override
          {tesseractLanguages = ["eng" "fra"];})

        zap # cybersecurity website test

        #math
        nasc
        kalker
        geogebra6
        octaveFull
      ];
  };
}
