{pkgs, ...}: {
  imports = [
    ./ghostwriter.nix
  ];

  environment.systemPackages = with pkgs; [
    onlyoffice-bin
    libreoffice-fresh
    hunspell
    hunspellDicts.fr-any
    pdfarranger
    rnote
  ];
}
