{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption optionals mkIf;
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

    hm.programs.gh = mkIf config.dev.enable {
      enable = true;
      settings.git_protocol = "ssh";
    };

    environment.systemPackages =
      with pkgs;
      [ ]
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
        glab
        flyctl
        clang
        nixd
        ungit
      ];

    hm.home.file.".zfunc/_poetry" = {
      source = ./poetry_completion.zsh;
    };
  };
}
