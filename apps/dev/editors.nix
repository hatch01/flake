{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption optionals;
in {
  imports = [
    ./vscode.nix
  ];

  options = {
    jetbrains.enable = mkEnableOption "jetbrains";
  };

  config = {
    platformio.enable = true;
    environment.systemPackages = with pkgs;
      [
        neovide
        zed-editor
        kate
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
