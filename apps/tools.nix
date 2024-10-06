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

  config = mkIf config.basic-tools.enable {
    environment.systemPackages = with pkgs; [
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
