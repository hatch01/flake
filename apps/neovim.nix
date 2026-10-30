{
  config,
  lib,
  inputs,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.neovim = {
    enable = mkEnableOption "Enable Neovim";
    nvchad.enable = mkEnableOption "Enable Neovim via nvchad (full IDE) instead of plain Neovim";
  };

  config = mkIf config.neovim.enable {
    environment.systemPackages = [
      (
        if config.neovim.nvchad.enable then
          inputs.nix4nvchad.packages.${system}.nvchad
        else
          (pkgs.neovim.override { waylandSupport = false; })
      )
    ];
    environment.variables.EDITOR = "nvim";
    hm.home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
