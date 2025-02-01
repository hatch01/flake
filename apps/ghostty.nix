{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    ghostty = {
      enable = mkEnableOption "enable ghostty";
    };
  };
  config = mkIf config.ghostty.enable {
    environment.systemPackages = [
      inputs.ghostty.packages.${pkgs.system}.default
    ];
    hm.home = {
      file.".config/ghostty/config".text = ''
        theme = catppuccin-mocha
        font-family = JetBrainsMono Nerd Font
        font-size = 9
        window-decoration = server

        keybind = performable:ctrl+v=paste_from_clipboard
        keybind = performable:ctrl+c=copy_to_clipboard
      '';
    };
  };
}
