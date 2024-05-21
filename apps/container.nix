{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) optionals mkEnableOption mkIf;
in {
  options = {
    container.enable = mkEnableOption "Enable container support";
    container.distrobox.enable = mkEnableOption "Enable distrobox";
  };

  config = mkIf config.container.enable {
    environment = {
      systemPackages = with pkgs;
        [
          docker-compose
          podman-compose
        ]
        ++ optionals config.container.distrobox.enable [
          distrobox
        ];
    };

    virtualisation = {
      docker = {
        enable = true;
        storageDriver = "btrfs";
        enableNvidia = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
