{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    cloud-storage.enable = mkEnableOption "Enable cloud storage services";
  };

  config = mkIf config.cloud-storage.enable {
    environment.systemPackages = with pkgs; [
      nextcloud-client
    ];
  };
}
