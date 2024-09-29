{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    homebank.enable = mkEnableOption "homebank";
  };

  config = mkIf config.homebank.enable {
    environment.systemPackages = with pkgs; [
      homebank
    ];

    hm = {
      programs.plasma = {
        configFile = {
          "homebank/preferences" = {
            "Exchange" = {
              "DateFmt".value = 1;
            };
          };
        };
      };
    };
  };
}
