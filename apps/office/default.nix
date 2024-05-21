{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) optionals mkEnableOption;
in {
  imports = [
    ./ghostwriter.nix
  ];

  options = {
    libreoffice.enable = mkEnableOption "libreoffice";
    onlyoffice.enable = mkEnableOption "onlyoffice";
  };

  config = {
    environment.systemPackages = with pkgs;
      [
        pdfarranger
        rnote
      ]
      ++ optionals config.libreoffice.enable [
        libreoffice-fresh
        hunspell
        hunspellDicts.fr-any
      ]
      ++ optionals config.onlyoffice.enable [
        onlyoffice-bin
      ];
  };
}
