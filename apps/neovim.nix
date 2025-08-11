{
  config,
  pkgs,
  lib,
  inputs,
  system,
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
    environment.systemPackages = [
      inputs.nix4nvchad.packages.${system}.nvchad
    ];
    environment.variables.EDITOR = "nvim";
    hm.home.sessionVariables = {
      EDITOR = "nvim";
    };
    #    programs.neovim = {
    #      #enable = true;
    #      defaultEditor = true;
    #      viAlias = true;
    #      vimAlias = true;
    #      configure = {
    #        customRC = ''
    #          set shiftwidth=2
    #            set ignorecase
    #        '';
    #      };
    #    };
  };
}
