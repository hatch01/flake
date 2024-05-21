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
    basic-tools.enable = mkDefault true;
    environment.systemPackages = with pkgs;
      mkIf config.basic-tools.enable [
        krename
        localsend
        minder
        kshutdown
        textpieces
        kdePackages.filelight
        electrum
        geogebra6

        zap # cybersecurity website test

        #math
        nasc
        kalker
      ];
  };
}
