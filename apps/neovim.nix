{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    neovim.enable = mkEnableOption "Enable Neovim";
  };

  config = mkIf config.neovim.enable {
    hm = {
      imports = [
        inputs.nix4nvchad.homeManagerModule
      ];
      programs.nvchad = {
        enable = true;
      };

      programs.neovim = {
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        extraConfig = ''
          set shiftwidth=2
          set ignorecase
        '';
      };
    };
  };
}
