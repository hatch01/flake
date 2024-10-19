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
    onlyofficeDesktopEditor.enable = mkEnableOption "onlyoffice desktop editor";
    office.enable = mkEnableOption "office";
  };

  config = {
    environment.systemPackages = with pkgs;
      []
      ++ optionals config.office.enable
      [
        pdfarranger
        rnote
      ]
      ++ optionals config.libreoffice.enable [
        libreoffice-fresh
        hunspell
        hunspellDicts.fr-any
      ]
      ++ optionals config.onlyofficeDesktopEditor.enable [
        onlyoffice-bin
      ];
  };
}
