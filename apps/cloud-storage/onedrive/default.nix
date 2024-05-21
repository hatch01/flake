{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  hm = mkIf config.cloud-storage.enable {
    home.packages = with pkgs; [onedrive];
    home.file.".config/onedrive/config" = {
      source = ./config;
      force = true;
    };
  };
}
