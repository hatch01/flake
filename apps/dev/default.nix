{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption optionals;
in
{
  imports = [
    ./editors.nix
    ./arduino.nix
  ];

  options = {
    dev.enable = mkEnableOption "dev";
    dev.androidtools.enable = mkEnableOption "androidtools";
  };

  config = {
    environment.systemPackages =
      with pkgs;
      [ glab ]
      ++ optionals config.dev.androidtools.enable [
        android-tools
        scrcpy
      ]
      ++ optionals config.dev.enable [
        insomnia
        minikube
        httpy-cli
        jq
        httptoolkit
        statix
        deadnix
      ];

    hm.home.file.".zfunc/_poetry" = {
      source = ./poetry_completion.zsh;
    };
  };
}
