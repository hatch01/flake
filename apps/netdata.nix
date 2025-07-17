{
  lib,
  config,
  pkgs,
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
    ;
in
{
  options = {
    netdata = {
      enable = mkEnableOption "enable Netdata";
      domain = mkOption {
        type = types.str;
        default = "netdata.${base_domain_name}";
        description = "The domain of the Netdata instance";
      };
      port = mkOption {
        type = types.int;
        default = 19999;
        description = "The port of the Netdata instance WARNING THIS HAS NO REAL EFFECT";
      };
    };
  };

  config = mkIf config.netdata.enable {
    age.secrets = mkSecret "server/netdata_notify" {
      root = true;
      owner = "netdata";
      group = "netdata";
    };

    systemd.services.netdata = {
      after = [
        "nginx.service"
        "postgresql.service"
        "fail2ban.service"
      ];
    };

    users = {
      users.netdata = {
        isSystemUser = true;
        group = "netdata";
        extraGroups = [ "smtp" ];
      };
    };

    services = {
      netdata = {
        enable = true;
        package = pkgs.netdata.override {
          withNdsudo = true;
          withCloudUi = true;
          withDebug = true;
          withDBengine = true;
        };
        extraNdsudoPackages = with pkgs; [
          fail2ban
          smartmontools
        ];
        config = {
          global = {
            # uncomment to reduce memory to 32 MB
            #"page cache size" = 32;

            # update interval
            "update every" = 15;
            "memory mode" = "map";
          };
          logs = {
            level = "info";
          };
          ml = {
            "enabled" = "yes";
          };
          db = {
            mode = "dbengine";
            "storage tiers" = 3;
            "dbengine tier 0 retention time" = "14d";
            "dbengine tier 1 retention time" = "3mo";
            "dbengine tier 2 retention time" = "2y";
          };
        };
        configDir = {
          "go.d/nginx.conf" = pkgs.writeText "nginx.conf" (
            lib.generators.toYAML { } {
              jobs = [
                {
                  name = "local";
                  url = "http://127.0.0.1/stub_status";
                }
              ];
            }
          );
          "go.d/fail2ban.conf" = pkgs.writeText "fail2ban.conf" (
            lib.generators.toYAML { } {
              jobs = [
                {
                  name = "fail2ban";
                  update_every = 5;
                }
              ];
            }
          );
          "go.d/smartctl.conf" = pkgs.writeText "smartctl.conf" (
            lib.generators.toYAML { } {
              jobs = [
                {
                  name = "smartctl";
                  devices_poll_interval = 60;
                }
              ];
            }
          );
          "go.d/zfspool.conf" = pkgs.writeText "zfspool.conf" (
            lib.generators.toYAML { } {
              jobs = [
                {
                  name = "zfspool";
                  binary_path = lib.getExe' pkgs.zfs "zpool";
                }
              ];
            }
          );
          "health_alarm_notify.conf" = config.age.secrets."server/netdata_notify".path;
        };
      };

      # enable nginx status page to get nginx stats
      nginx.virtualHosts = {
        "_" = {
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

      #setup postgresql netdata user to access postgresql stats
      postgresql = {
        enable = true;
        ensureUsers = [
          { name = "netdata"; }
        ];
      };
    };

    environment.persistence."/persistent" = {
      directories = [
        "/var/lib/netdata"
        "/var/cache/netdata"
      ];
    };
    postgres.initialScripts = [ "GRANT pg_monitor TO netdata;" ];
  };
}
