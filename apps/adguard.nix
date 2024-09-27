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
        default = 3000;
        description = "The port on which Adguard will listen";
      };
    };
  };

  config = mkIf config.adguard.enable {
    services.adguardhome = {
      enable = true;
      settings = {
        http = {
          address = "0.0.0.0:${toString config.adguard.port}";
        };
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
          ];
      };
    };
    networking.firewall.allowedTCPPorts = [53];
  };
}
