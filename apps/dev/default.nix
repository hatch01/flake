{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption optionals;
in {
  imports = [
    ./editors.nix
  ];

  options = {
    dev.enable = mkEnableOption "dev";
    dev.androidtools.enable = mkEnableOption "androidtools";
  };

  config = {
    environment.systemPackages = with pkgs;
      []
      ++ optionals config.dev.androidtools.enable
      [
        android-studio
        scrcpy
      ]
      ++ optionals config.dev.enable [
        insomnia
        minikube
        httpy-cli
        jq
        openjdk19
      ];
  };
}
