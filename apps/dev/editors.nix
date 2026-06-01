{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optionals
    mkDefault
    ;
in
{
  imports = [
    ./vscode.nix
  ];

  options = {
    jetbrains.enable = mkEnableOption "jetbrains";
  };

  config = mkIf config.dev.enable {
    arduino.enable = mkDefault true;
    environment.systemPackages =
      with pkgs;
      [
        neovide
        zed-editor
        kdePackages.kate
        gemini-cli
      ]
      ++ optionals config.jetbrains.enable [
        jetbrains.idea
        jetbrains.pycharm
        jetbrains.clion
        jetbrains.rust-rover
        jetbrains.phpstorm
        jetbrains.datagrip
      ];
    programs.zsh.shellInit = "export GOOGLE_CLOUD_PROJECT=\"gbr-mts-ctoo-utils-dev\"";
  };
}
