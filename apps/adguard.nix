{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    adguard = {
      enable = mkEnableOption "enable Adguard";
      hostName = mkOption {
        type = types.str;
        default = "adguard.${config.hostName}";
        description = "The hostname of the Adguard instance";
      };
      port = mkOption {
        type = types.int;
        default = 3001;
        description = "The port on which Adguard will listen";
      };
    };
  };

  config = mkIf config.adguard.enable {
    users.users.adguardhome = {
      group = "nginx"; # needed to read the certificates
      isSystemUser = true;
    };
    systemd.services.adguardhome.serviceConfig = {
      User = "adguardhome";
    };
    services.adguardhome = {
      enable = true;
      host = "[::1]";
      settings = {
        dns = {
          upstream_dns = [
            "9.9.9.9" #dns.quad9.net
            "149.112.112.112" #dns.quad9.net
          ];
          anonymize_client_ip = true;
          enable_dnssec = true;
        };
        tls = {
          enabled = true;
          force_https = true;
          port_dns_over_tls = 853;
          port_dns_over_quic = 853;
          port_https = config.adguard.port;
          allow_unencrypted_doh = true;
          server_name = config.adguard.hostName;
          certificate_path = "/var/lib/acme/${config.adguard.hostName}/fullchain.pem";
          private_key_path = "/var/lib/acme/${config.adguard.hostName}/key.pem";
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;

          parental_enabled = false; # Parental control-based DNS requests filtering.
          safe_search.enabled = false; # Enforcing "Safe search" option for search engines, when possible.
        };

        statistics = {
          enable = false;
        };
        querylog = {
          enable = false;
        };
        log = {
          file = "log.txt";
        };
        # The following notation uses map
        # to not have to manually create {enabled = true; url = "";} for every filter
        # This is, however, fully optional
        filters =
          map (url: {
            enabled = true;
            url = url;
          }) [
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt" # uBlock₀ filters – Badware risk
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt" # AdGuard DNS filter
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt" # AdGuard DNS Popup Hosts filter
          ];
      };
    };
    networking.firewall.allowedTCPPorts = [853];
  };
}
