{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
in
{
  imports = [
    ./vscode.nix
  ];

  options = {
    jetbrains.enable = mkEnableOption "jetbrains";
  };

  config = mkIf config.dev.enable {
    arduino.enable = true;
    environment.systemPackages =
      with pkgs;
      [
        neovide
        zed-editor
        kdePackages.kate
      ]
      ++ optionals config.jetbrains.enable [
        jetbrains.idea-ultimate
        jetbrains.pycharm-professional
        jetbrains.clion
        jetbrains.rust-rover
        jetbrains.phpstorm
        jetbrains.datagrip
      ];
  };
}
