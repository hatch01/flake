{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault mkIf;
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
        electrum

        zap # cybersecurity website test

        #math
        nasc
        kalker
        geogebra6
        octaveFull
      ];
  };
}
