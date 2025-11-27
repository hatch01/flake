{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    optionals
    mkEnableOption
    mkIf
    mkDefault
    ;
in
{
  options = {
    container.enable = mkEnableOption "Enable container support";
    container.docker.enable = mkEnableOption "Enable Docker";
    container.podman.enable = mkEnableOption "Enable Podman";
    container.distrobox.enable = mkEnableOption "Enable distrobox";
  };

  config = mkIf config.container.enable {
    container.docker.enable = mkDefault true;
    container.podman.enable = mkDefault true;

    environment = {
      systemPackages =
        with pkgs;
        optionals config.container.podman.enable [
          podman-compose
        ]
        ++ optionals config.container.distrobox.enable [
          distrobox
        ];
    };

    virtualisation = {
      docker = mkIf config.container.docker.enable {
        enable = true;
        storageDriver = "btrfs";
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
        # Configure DNS servers for containers to fix DNS resolution
        daemon.settings = {
          dns = [
            "9.9.9.9"
            "149.112.112.112"
          ];
        };
      };
      podman = mkIf config.container.podman.enable {
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
