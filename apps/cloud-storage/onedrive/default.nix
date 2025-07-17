{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.cloud-storage.enable {
    services.onedrive.enable = true;
    environment.systemPackages = with pkgs; [ onedrive ];
    hm.home.file.".config/onedrive/config" = {
      source = ./config;
      force = true;
    };
  };
}
