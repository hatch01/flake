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
    ./arduino.nix
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
        android-tools
        scrcpy
      ]
      ++ optionals config.dev.enable [
        insomnia
        minikube
        httpy-cli
        jq
        httptoolkit
      ];
  };
}
