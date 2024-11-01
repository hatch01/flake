{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  imports = [
    # ./onedrive
  ];

  options = {
    cloud-storage.enable = mkEnableOption "Enable cloud storage services";
  };

  config = mkIf config.cloud-storage.enable {
    environment.systemPackages = with pkgs; [
      syncthing
      syncthingtray
      nextcloud-client
    ];
  };
}
