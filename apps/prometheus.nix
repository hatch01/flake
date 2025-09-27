# Prometheus monitoring module with exporters
#
# This module provides a clean, structured approach to configuring Prometheus
# with multiple exporters. Key improvements:
# - All exporters listen only on 127.0.0.1 for security
# - Uses NixOS default ports for exporters (no duplication)
# - Scrape configs are automatically generated from exporter configurations
# - Conditional enabling based on other service availability
# - Reduced repetition through helper functions
#
# Example usage to customize exporter ports:
# services.prometheus.exporters.node.port = 9101;
# services.prometheus.exporters.nginx.port = 9114;

{
  lib,
  config,
  base_domain_name,
  mkSecret,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    mkForce
    mapAttrsToList
    filterAttrs
    ;

  # Helper function to create an exporter configuration
  # Ensures all exporters listen on localhost only
  mkExporter =
    name: baseConfig:
    {
      enable = true;
      listenAddress = "127.0.0.1";
    }
    // baseConfig;

  # Define all available exporters with their configurations and conditions
  # Each exporter has a condition that determines if it should be enabled
  availableExporters = {
    node = {
      condition = true; # Always enabled when prometheus is enabled
      config = {
        enabledCollectors = [ "systemd" ];
      };
    };

    process = {
      condition = true; # Process monitoring and statistics
    };

    smartctl = {
      condition = true; # SMART disk health monitoring
      config = {
        devices = config.prometheus.smartctl.devices;
      };
    };

    zfs = {
      condition = true; # ZFS filesystem metrics
    };

    # === Service Monitoring ===
    nginx = {
      condition = true; # Nginx web server metrics
      config = {
        scrapeUri = "http://localhost/stub_status";
      };
    };

    postgres = {
      condition = config.prometheus.postgres; # PostgreSQL database metrics
      config = {
        runAsLocalSuperUser = true;
      };
    };

    # === Application Monitoring ===
    nextcloud = {
      condition = config.nextcloud.enable or false; # Nextcloud application metrics
      config = {
        tokenFile = config.age.secrets.nextcloud_prometheus.path;
        url = "https://${config.nextcloud.domain}";
      };
    };

    mqtt = {
      condition = config.zigbee2mqtt.enable or false; # MQTT broker metrics
    };

    # === Backup Monitoring ===
    restic = {
      condition = true; # Backup status and statistics
      config = {
        repository = config.services.restic.backups.remotebackup.repository;
        passwordFile = config.services.restic.backups.remotebackup.passwordFile;
        user = "root";
      };
    };
  };

  # Filter exporters based on their conditions (e.g., service availability)
  enabledExporters = filterAttrs (name: exporter: exporter.condition) availableExporters;

  # Generate exporter configurations
  exporterConfigs = mapAttrsToList (name: exporter: {
    name = name;
    value = mkExporter name (exporter.config or { });
  }) enabledExporters;

  # Generate scrape configurations from the actual exporter configs
  scrapeConfigs = mapAttrsToList (name: exporter: {
    job_name = name;
    static_configs = [
      {
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}" ];
      }
    ];
  }) enabledExporters;

in
{
  options = {
    prometheus = {
      enable = mkEnableOption "Activer Prometheus";
      domain = mkOption {
        type = types.str;
        default = "prometheus.${base_domain_name}";
        description = "Domaine de l'instance Prometheus";
      };
      port = mkOption {
        type = types.int;
        default = 9092;
        description = "Port de Prometheus";
      };
      postgres = mkEnableOption "Activer l'exporter PostgreSQL";

      smartctl = {
        devices = mkOption {
          type = types.listOf types.str;
          default = [
            "/dev/sda"
            "/dev/sdb"
            "/dev/sdc"
          ];
          description = "Liste des périphériques à surveiller avec smartctl";
        };
      };

    };
  };

  config = mkIf config.prometheus.enable {
    age.secrets = mkIf (config.nextcloud.enable or false) (
      mkSecret "nextcloud_prometheus" { owner = "nextcloud-exporter"; }
    );

    systemd.services.prometheus-restic-exporter.serviceConfig.ProtectHome = mkForce false;

    services = {
      prometheus = {
        enable = true;
        port = config.prometheus.port;
        webExternalUrl = "https://${config.prometheus.domain}";

        # Generated scrape configurations
        scrapeConfigs = scrapeConfigs;

        # Generated exporter configurations
        exporters = builtins.listToAttrs exporterConfigs;
      };

      # Nginx configuration for stub_status (only if nginx exporter is enabled)
      nginx = mkIf (availableExporters.nginx.condition) {
        enable = true;
        virtualHosts."_" = {
          locations."/stub_status" = {
            extraConfig = ''
              stub_status on;
              access_log off;
              allow 127.0.0.1;
              deny all;
            '';
          };
        };
      };
    };

    environment.persistence."/persistent".directories = [
      "/var/lib/prometheus2"
    ];
  };
}
