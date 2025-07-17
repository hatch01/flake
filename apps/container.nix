{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) optionals mkEnableOption mkIf;
in
{
  options = {
    container.enable = mkEnableOption "Enable container support";
    container.distrobox.enable = mkEnableOption "Enable distrobox";
  };

  config = mkIf config.container.enable {
    environment = {
      systemPackages =
        with pkgs;
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

    hm.home = mkIf config.container.distrobox.enable {
      file.".distroboxrc".text = ''
        container_additional_volumes="/nix/store:/nix/store:ro /etc/static/profiles/per-user:/etc/profiles/per-user:ro"
      '';
    };
  };
}
