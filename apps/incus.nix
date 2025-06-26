{
  lib,
  config,
  base_domain_name,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options = {
    incus = {
      enable = mkEnableOption "Enable incus";
      domain = mkOption {
        type = types.str;
        default = "incus.${base_domain_name}";
        description = "The domain name for the incus server";
      };
      port = mkOption {
        type = types.int;
        default = 8007;
        description = "The port for the incus server";
      };
    };
  };

  config = mkIf config.incus.enable {
    networking.nftables.enable = true;
    networking.firewall.enable = false;
    virtualisation.incus = {
      enable = true;
      ui = {
        enable = true;
      };
      preseed = {
        config = {
          "core.https_address" = "[::]:${toString config.incus.port}";
          "oidc.issuer" = "https://${config.authelia.domain}";
          "oidc.client.id" = "incus";
          "oidc.audience" = "https://${config.incus.domain}";
        };
        networks = [
          {
            config = {
              "ipv4.address" = "auto";
              "ipv6.address" = "auto";
            };
            description = "";
            name = "incusbr0";
            type = "";
            project = "default";
          }
        ];
        storage_pools = [
          {
            config = {
              source = "/storage/incus";
            };
            description = "";
            name = "default";
            driver = "dir";
          }
        ];
        storage_volumes = [];
        profiles = [
          {
            config = {};
            description = "";
            devices = {
              eth0 = {
                name = "eth0";
                network = "incusbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
            name = "default";
            project = "default";
          }
        ];
        projects = [];
        cluster = null;
      };
    };
  };
}
