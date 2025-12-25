{
  lib,
  config,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
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
    networking.firewall.trustedInterfaces = [
      "incusbr*"
      "tailscale0"
    ];

    services.resolved = {
      enable = true;
      dnssec = "false";
      # Don't set a default domain - let each interface handle its own
      fallbackDns = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
      dnsovertls = "false";
    };

    # Systemd service to configure resolved for incusbr0
    systemd.services.incus-dns-incusbr0 = {
      description = "Incus per-link DNS configuration for incusbr0";
      bindsTo = [ "sys-subsystem-net-devices-incusbr0.device" ];
      after = [ "sys-subsystem-net-devices-incusbr0.device" ];
      wantedBy = [ "sys-subsystem-net-devices-incusbr0.device" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = ''
        # Get the DNS addresses from the bridge
        IPV4_ADDR=$(${config.virtualisation.incus.package}/bin/incus network get incusbr0 ipv4.address 2>/dev/null | cut -d'/' -f1 || echo "")
        IPV6_ADDR=$(${config.virtualisation.incus.package}/bin/incus network get incusbr0 ipv6.address 2>/dev/null | cut -d'/' -f1 || echo "")

        # Configure resolved with the DNS addresses
        if [ -n "$IPV4_ADDR" ]; then
          ${config.systemd.package}/bin/resolvectl dns incusbr0 "$IPV4_ADDR" || true
        fi
        if [ -n "$IPV6_ADDR" ]; then
          ${config.systemd.package}/bin/resolvectl dns incusbr0 "$IPV6_ADDR" || true
        fi

        # Configure DNS domain
        ${config.systemd.package}/bin/resolvectl domain incusbr0 '~incus' || true

        # Disable DNSSEC and DNS over TLS for the bridge
        ${config.systemd.package}/bin/resolvectl dnssec incusbr0 off || true
        ${config.systemd.package}/bin/resolvectl dnsovertls incusbr0 off || true
      '';
      preStop = ''
        ${config.systemd.package}/bin/resolvectl revert incusbr0 || true
      '';
    };

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
              "ipv4.dhcp" = "true";
              "ipv6.dhcp" = "true";
              "dns.mode" = "dynamic";
              "dns.domain" = "incus";
              # Set upstream DNS servers for VMs/containers
              "dns.zone.forward" = "true";
              "dns.zone.reverse.ipv4" = "true";
              "dns.zone.reverse.ipv6" = "true";
              # Use Cloudflare DNS as upstream
              "ipv4.dns" = "9.9.9.9,149.112.112.112";
              "ipv6.dns" = "2620:fe::fe,2620:fe::9";
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
        storage_volumes = [ ];
        profiles = [
          {
            config = { };
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
        projects = [ ];
        cluster = null;
      };
    };
  };
}
