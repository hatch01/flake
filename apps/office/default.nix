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
      ++ optionals config.onlyofficeDesktopEditor.enable [
        onlyoffice-bin
      ];
  };
}
