{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    nix-related.enable = mkEnableOption "Enable nix-related";
  };
  config = mkIf config.nix-related.enable {
    environment.systemPackages = with pkgs; [
      nix-forecast
      nil
    ];

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/etc/nixos";
    };
  };
}
