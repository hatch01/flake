{
  lib,
  config,
  mkSecrets,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    restic.enable = mkEnableOption "Enable restic backup";
  };

  config = mkIf config.restic.enable {
    age.secrets = mkSecrets {
      "server/cockpit_private_key" = {
        mode = "600";
        root = true;
      };
      "server/restic_key" = {
        root = true;
      };
      "server/influx_root_token" = {
        root = true;
      };
    };

    environment.systemPackages = [ pkgs.restic ];

    services.restic.backups = {
      remotebackup = {
        initialize = true;
        environmentFile = config.age.secrets."server/influx_root_token".path;
        pruneOpts = [ "--keep-last 7" ];
        paths = [
          "/storage"
        ];
        exclude = [
          "/storage/postgresql"
          "/storage/influxdb"
        ];
        passwordFile = config.age.secrets."server/restic_key".path;
        repository = "sftp://homeassistant/backup/backup_eymeric";

        backupPrepareCommand = ''
          ${lib.getExe pkgs.docker} exec -e INFLUX_TOKEN=$INFLUX_TOKEN influxdb influx backup /var/lib/influxdb2/influx.bak
          mv /storage/influxdb/influx.bak /storage/influx.bak
          ${lib.getExe' pkgs.sudo "sudo"} -u postgres ${lib.getExe' config.services.postgresql.package "pg_dumpall"} > /storage/postgres.sql
        '';

        backupCleanupCommand = ''
          rm /storage/postgres.sql
          rm -r /storage/influx.bak
        '';

        timerConfig = {
          OnCalendar = "00:00";
        };
      };
    };
  };
}
