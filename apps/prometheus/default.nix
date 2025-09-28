# Prometheus monitoring module with exporters and multi-host support
#
# This module provides a clean, structured approach to configuring Prometheus
# with multiple exporters across multiple hosts via Tailscale. Key features:
# - Local exporters listen on 127.0.0.1 for security
# - Remote exporters listen on Tailscale interface
# - Automatic scrape config generation for both local and remote hosts
# - Easy addition of new hosts via configuration
# - Conditional enabling based on service availability
#
# Example usage:
# prometheus = {
#   enable = true;
#   remoteHosts = {
#     lilas = {
#       exporters = ["node" "systemd" "zfs"];
#     };
#   };
# };

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
    ;

  # Helper function to create a local exporter configuration
  # Local exporters listen on localhost only for security
  mkLocalExporter =
    name: baseConfig:
    {
      enable = true;
      listenAddress = "127.0.0.1";
    }
    // baseConfig;

  # Helper function to create a remote exporter configuration
  # Remote exporters listen on all interfaces (0.0.0.0) for Tailscale access
  mkRemoteExporter =
    name: baseConfig:
    {
      enable = true;
      listenAddress = "0.0.0.0";
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
    mqtt.enable = config.zigbee2mqtt.enable; # MQTT broker metrics
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

    nextcloud = {
      enable = config.nextcloud.enable; # Nextcloud application metrics
      config = {
        tokenFile = config.age.secrets.nextcloud_prometheus.path;
        url = "https://${config.nextcloud.domain}";
      };
    };

    restic = {
      enable = true; # Backup status and statistics
      config = {
        repository = config.services.restic.backups.remotebackup.repository;
        passwordFile = config.services.restic.backups.remotebackup.passwordFile;
        user = "root";
      };
    };
  };

  # Determine if this is the Prometheus server host
  isPrometheusHost = config.prometheus.enable;

  # Filter exporters based on their conditions and host type
  enabledLocalExporters =
    if isPrometheusHost then filterAttrs (name: exporter: exporter.enable) availableExporters else { };

  # For remote hosts, only enable basic exporters or specified ones
  enabledRemoteExporters =
    if !isPrometheusHost && config.prometheus.exporters.enable then
      filterAttrs (
        name: exporter: builtins.elem name config.prometheus.exporters.enabled && exporter.enable
      ) availableExporters
    else
      { };

  # Generate local exporter configurations (for Prometheus host)
  localExporterConfigs = mapAttrsToList (name: exporter: {
    name = name;
    value = mkLocalExporter name (exporter.config or { });
  }) enabledLocalExporters;

  # Generate remote exporter configurations (for non-Prometheus hosts)
  remoteExporterConfigs =
    if !isPrometheusHost && config.prometheus.exporters.enable then
      mapAttrsToList (name: exporter: {
        name = name;
        value = mkRemoteExporter name (exporter.config or { });
      }) enabledRemoteExporters
    else
      [ ];

  # Generate scrape configurations for local exporters
  localScrapeConfigs = mapAttrsToList (name: exporter: {
    job_name = "${name}-${config.networking.hostName}";
    static_configs = [
      {
        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.${name}.port}" ];
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
  }) enabledLocalExporters;

  # Generate scrape configurations for remote hosts
  remoteScrapeConfigs = flatten (
    mapAttrsToList (
      hostName: hostConfig:
      map (exporterName: {
        job_name = "${exporterName}-${hostName}";
        static_configs = [
          {
            targets = [
              "${hostName}:${toString config.services.prometheus.exporters.${exporterName}.port}"
            ];
            labels = {
              hostname = hostName;
            };
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "hostname" ];
            target_label = "instance";
          }
        ];
      }) hostConfig.exporters
    ) config.prometheus.remoteHosts
  );

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
      enable = mkEnableOption "Activer Prometheus (serveur principal)";

      # Options for remote hosts (non-Prometheus hosts)
      exporters = {
        enable = mkEnableOption "Activer les exporters sur cet hôte";
        enabled = mkOption {
          type = types.listOf types.str;
          default = [
            "node"
            "systemd"
            "process"
          ];
          description = "Liste des exporters à activer sur cet hôte";
        };
      };

      # Remote hosts configuration (only used on Prometheus host)
      remoteHosts = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              exporters = mkOption {
                type = types.listOf types.str;
                default = [
                  "node"
                  "systemd"
                  "process"
                ];
                description = "Liste des exporters à scraper sur cet hôte";
              };
            };
          }
        );
        default = { };
        description = "Configuration des hôtes distants à monitorer";
      };

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

  config = mkIf (config.prometheus.enable || config.prometheus.exporters.enable) {

    # Secrets (only on Prometheus host)
    age.secrets = mkIf config.prometheus.enable (
      mkSecrets (
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
      )
    );

    # Fix for restic exporter (only if enabled)
    systemd.services = mkIf (config.prometheus.enable && enabledLocalExporters ? restic) {
      prometheus-restic-exporter.serviceConfig.ProtectHome = mkForce false;
    };

    services = {
      # Prometheus server configuration (only on Prometheus host)
      prometheus = mkIf config.prometheus.enable {
        enable = true;
        port = config.prometheus.port;
        webExternalUrl = "https://${config.prometheus.domain}";

        # Combined scrape configurations (local + remote)
        scrapeConfigs =
          localScrapeConfigs
          ++ remoteScrapeConfigs
          ++ [
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

        # Local exporter configurations
        exporters = builtins.listToAttrs localExporterConfigs;

        # Alert rules (only on Prometheus host)
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

          checkConfig = false;
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

      # Remote exporter configurations (only on non-Prometheus hosts)
      prometheus.exporters = mkIf config.prometheus.exporters.enable (
        builtins.listToAttrs remoteExporterConfigs
      );

      # Nginx configuration for stub_status (only if nginx exporter is enabled)
      nginx =
        mkIf
          (
            enabledLocalExporters ? nginx
            || (config.prometheus.exporters.enable && builtins.elem "nginx" config.prometheus.exporters.enabled)
          )
          {
            enable = true;
            virtualHosts."_" = {
              locations."/stub_status" = {
                extraConfig = ''
                  stub_status on;
                  access_log off;
                  allow 127.0.0.1;
                  allow 100.64.0.0/10;  # Allow Tailscale network
                  deny all;
                '';
              };
            };
          };
    };

    # Persistence (only on Prometheus host)
    environment.persistence."/persistent".directories = mkIf config.prometheus.enable [
      "/var/lib/prometheus2"
    ];
  };
}
