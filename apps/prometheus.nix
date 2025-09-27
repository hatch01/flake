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
    optionals
    mkForce
    ;
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
    };
  };

  config = mkIf config.prometheus.enable {
    age.secrets = mkSecret "nextcloud_prometheus" { owner = "nextcloud-exporter"; };
    systemd.services.prometheus-restic-exporter.serviceConfig.ProtectHome = mkForce false;
    services = {
      prometheus = {
        enable = true;
        port = config.prometheus.port;
        webExternalUrl = "https://${config.prometheus.domain}";

        # # Configuration des scrape targets
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [ { targets = [ "localhost:9100" ]; } ];
          }
        ]
        ++ [
          {
            job_name = "nginx";
            static_configs = [ { targets = [ "localhost:9113" ]; } ];
          }
        ]
        ++ [
          {
            job_name = "zfs";
            static_configs = [ { targets = [ "localhost:9134" ]; } ];
          }
        ]
        ++ optionals config.prometheus.postgres [
          {
            job_name = "postgres";
            static_configs = [ { targets = [ "localhost:9187" ]; } ];
          }
        ]
        ++ [
          {
            job_name = "mqtt";
            static_configs = [ { targets = [ "localhost:9000" ]; } ];
          }
        ]
        ++ [
          {
            job_name = "restic";
            static_configs = [ { targets = [ "localhost:9753" ]; } ];
          }
        ]
        ++ optionals config.nextcloud.enable [
          {
            job_name = "nextcloud";
            static_configs = [ { targets = [ "localhost:9205" ]; } ];
          }

        ]
        ++ [
          {
            job_name = "process";
            static_configs = [ { targets = [ "localhost:9256" ]; } ];
          }
        ]
        ++ [
          {
            job_name = "smartctl";
            static_configs = [ { targets = [ "localhost:9633" ]; } ];
          }
        ];

        # Fichier d'alertes (à créer)
        # ruleFiles = [ ./alert.rules ];
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
          };
          postgres = mkIf config.prometheus.postgres {
            enable = true;
            runAsLocalSuperUser = true;
          };
          nginx = {
            enable = true;
            scrapeUri = "http://localhost/stub_status";
          };
          nextcloud = mkIf config.nextcloud.enable {
            enable = true;
            # # Generate random value (for example using openssl)
            # TOKEN=$(openssl rand -hex 32)
            # # Set token (using the occ console application)
            # occ config:app:set serverinfo token --value "$TOKEN"
            tokenFile = config.age.secrets.nextcloud_prometheus.path;
            url = "https://${config.nextcloud.domain}";
          };
          mqtt = mkIf config.zigbee2mqtt.enable {
            enable = true;
          };
          zfs = {
            enable = true;
          };
          restic = {
            enable = true;
            repository = config.services.restic.backups.remotebackup.repository;
            passwordFile = config.services.restic.backups.remotebackup.passwordFile;
            user = "root";
          };
          process = {
            enable = true;
          };
          smartctl = {
            enable = true;
            devices = [
              "/dev/sda"
              "/dev/sdb"
              "/dev/sdc"
            ];
          };
        };
      };
      # Nginx (pour les métriques stub_status)
      nginx = {
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
