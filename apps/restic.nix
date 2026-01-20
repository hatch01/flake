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
    };

    environment.systemPackages = [ pkgs.restic ];

    services.restic.backups = {
      remotebackup = {
        initialize = true;
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
          ${lib.getExe' pkgs.sudo "sudo"} -u postgres ${lib.getExe' config.services.postgresql.package "pg_dumpall"} > /storage/postgres.sql
        '';

        backupCleanupCommand = ''
          rm /storage/postgres.sql
        '';

        timerConfig = {
          OnCalendar = "00:00";
        };
      };
    };
  };
}
