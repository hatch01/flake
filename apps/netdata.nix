{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    netdata = {
      enable = mkEnableOption "enable Netdata";
      hostName = mkOption {
        type = types.str;
        default = "netdata.${config.networking.hostName}";
        description = "The hostname of the Netdata instance";
      };
      port = mkOption {
        type = types.int;
        default = 19999;
        description = "The port of the Netdata instance WARNING THIS HAS NO REAL EFFECT";
      };
    };
  };

  config = mkIf config.netdata.enable {
    services = {
      netdata = {
        enable = true;
        config = {
          global = {
            # uncomment to reduce memory to 32 MB
            #"page cache size" = 32;

            # update interval
            "update every" = 15;
            "memory mode" = "map";
          };
          ml = {
            "enabled" = "yes";
          };
          db = {
            mode = "dbengine";
            "storage tiers" = 3;

            # Tier 0, per second data
            "dbengine multihost disk space MB" = 1024;

            # Tier 1, per minute data
            "dbengine tier 1 multihost disk space MB" = 1024;

            # Tier 2, per hour data
            "dbengine tier 2 multihost disk space MB" = 1024;
          };
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
              deny all;'';
          };
        };
      };

      #setup postgresql netdata user to access postgresql stats
      postgresql = {
        enable = true;
        ensureUsers = [
          {name = "netdata";}
        ];
      };
    };
    postgres.initialScripts = ["GRANT pg_monitor TO netdata;"];
  };
}
