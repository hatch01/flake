{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    nix-related.enable = mkEnableOption "Enable nix-related";
  };
  config = mkIf config.nix-related.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/etc/nixos";
    };
    environment.systemPackages = with pkgs; [
      fh
    ];
  };
}
