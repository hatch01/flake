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
  mkSecrets,
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
    filesystem
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
      enable = true; # Always enabled when prometheus is enabled
      config = {
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
    };

    process.enable = true; # Process monitoring and statistics
    zfs.enable = true; # ZFS filesystem metrics
    mqtt.enable = config.zigbee2mqtt.enable or false; # MQTT broker metrics
    systemd.enable = true; # Systemd service metrics

    smartctl = {
      enable = true; # SMART disk health monitoring
      config = {
        devices = config.prometheus.smartctl.devices;
      };
    };

    # === Service Monitoring ===
    nginx = {
      enable = true; # Nginx web server metrics
      config = {
        scrapeUri = "http://localhost/stub_status";
      };
    };

    postgres = {
      enable = config.prometheus.postgres; # PostgreSQL database metrics
      config = {
        runAsLocalSuperUser = true;
      };
    };

    # === Application Monitoring ===
    nextcloud = {
      enable = config.nextcloud.enable or false; # Nextcloud application metrics
      config = {
        tokenFile = config.age.secrets.nextcloud_prometheus.path;
        url = "https://${config.nextcloud.domain}";
      };
    };

    # === Backup Monitoring ===
    restic = {
      enable = true; # Backup status and statistics
      config = {
        repository = config.services.restic.backups.remotebackup.repository;
        passwordFile = config.services.restic.backups.remotebackup.passwordFile;
        user = "root";
      };
    };
  };

  # Filter exporters based on their conditions (e.g., service availability)
  enabledExporters = filterAttrs (name: exporter: exporter.enable) availableExporters;

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
        labels = {
          hostname = config.networking.hostName;
        };
      }
    ];
    # Relabel to ensure that the instance label is set to the hostname
    relabel_configs = [
      {
        source_labels = [ "hostname" ];
        target_label = "instance";
      }
    ];
  }) enabledExporters;

  # Automatically load all rule files from alerts subfolder
  ruleFiles =
    let
      alertsPath = config.prometheus.alertsPath;
    in
    map (name: alertsPath + "/${name}") (lib.attrNames (builtins.readDir alertsPath));

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

      alertManager = {
        domain = mkOption {
          type = types.str;
          default = "alertmanager.${base_domain_name}";
          description = "Domaine de l'instance Alert Manager";
        };
        port = mkOption {
          type = types.int;
          default = 9093;
          description = "Port de l'Alert Manager";
        };
      };

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

      alertsPath = mkOption {
        type = types.path;
        default = ./alerts;
        description = "Path to the alerts directory containing rule files";
      };

    };
  };

  config = mkIf config.prometheus.enable {
    age.secrets = mkSecrets (
      {
        discord_prometheus = {
          owner = "prometheus";
        };
      }
      // (
        if config.nextcloud.enable then
          {
            nextcloud_prometheus = {
              owner = "nextcloud-exporter";
            };
          }
        else
          { }
      )
    );

    systemd.services.prometheus-restic-exporter.serviceConfig.ProtectHome = mkForce false;

    services = {
      prometheus = {
        enable = true;
        port = config.prometheus.port;
        webExternalUrl = "https://${config.prometheus.domain}";

        # Generated scrape configurations
        scrapeConfigs = scrapeConfigs ++ [
          # Prometheus self-monitoring
          {
            job_name = "prometheus";
            static_configs = [
              {
                targets = [ "localhost:${toString config.prometheus.port}" ];
                labels = {
                  hostname = config.networking.hostName;
                };
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "hostname" ];
                target_label = "instance";
              }
            ];
          }
          # Alertmanager monitoring
          {
            job_name = "alertmanager";
            static_configs = [
              {
                targets = [ "localhost:${toString config.prometheus.alertManager.port}" ];
                labels = {
                  hostname = config.networking.hostName;
                };
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "hostname" ];
                target_label = "instance";
              }
            ];
          }
        ];

        # Generated exporter configurations
        exporters = builtins.listToAttrs exporterConfigs;

        # Automatically loaded alert rules from alerts subfolder
        ruleFiles = ruleFiles;

        alertmanagers = [
          {
            static_configs = [ { targets = [ "localhost:${toString config.prometheus.alertManager.port}" ]; } ];
          }
        ];

        alertmanager = {
          enable = true;
          port = config.prometheus.alertManager.port;
          webExternalUrl = "https://${config.prometheus.alertManager.domain}";
          environmentFile = config.age.secrets.discord_prometheus.path;
          checkConfig = false; # Disable because the url is provided by env file which is not available at check time
          configuration = {
            route = {
              receiver = "discord";
              group_by = [ "alertname" ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "3h";
            };
            receivers = [
              {
                name = "discord";
                discord_configs = [
                  {
                    webhook_url = "\${webhook}";
                  }
                ];
              }
            ];
          };
        };

      };

      # Nginx configuration for stub_status (only if nginx exporter is enabled)
      nginx = mkIf (availableExporters.nginx.enable) {
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
