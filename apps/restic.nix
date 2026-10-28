{
  lib,
  config,
  mkSecrets,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
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
        path = "/root/.ssh/id_rsa";
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
          "/storage/backup_guillaume"
          "/storage/.snapshots"
        ]
        ++ optionals config.bitcoin.server.enable [
          "/storage/bitcoin"
        ];
        passwordFile = config.age.secrets."server/restic_key".path;
        repository = "sftp://homeassistant/backup/backup_eymeric";

        backupPrepareCommand = ''
          ${lib.getExe' pkgs.sudo "sudo"} -u postgres ${lib.getExe' config.services.postgresql.package "pg_dumpall"} > /storage/postgres.sql
        '';

        backupCleanupCommand = ''
          ${lib.getExe' pkgs.coreutils "rm"} -f /storage/postgres.sql

          if [ "''${SERVICE_RESULT:-}" != "success" ] || [ "''${EXIT_STATUS:-0}" != "0" ]; then
            FAILED=1
            STATUS="FAILED"
          else
            FAILED=0
            STATUS="SUCCESS"
          fi

          ${lib.getExe' pkgs.systemd "journalctl"} --sync 2>/dev/null || true

          OUTPUT=""
          if [ -n "''${INVOCATION_ID:-}" ]; then
            OUTPUT=$(${lib.getExe' pkgs.systemd "journalctl"} _SYSTEMD_INVOCATION_ID="$INVOCATION_ID" -o cat --no-pager 2>&1 || true)
          fi
          if [ -z "$OUTPUT" ]; then
            OUTPUT=$(${lib.getExe' pkgs.systemd "journalctl"} -u restic-backups-remotebackup.service -n 500 -o cat --no-pager 2>&1 || echo "No logs found")
          fi

          {
            echo "To: root"
            if [ "$FAILED" -eq 1 ]; then
              echo "Importance: high"
              echo "X-Priority: 1"
              echo "X-MSMail-Priority: High"
              echo "Priority: urgent"
              echo "Subject: [restic] [FAILED] Backup remotebackup on ${config.networking.hostName}"
            else
              echo "Subject: [restic] [SUCCESS] Backup remotebackup on ${config.networking.hostName}"
            fi
            echo ""
            if [ "$FAILED" -eq 1 ]; then
              echo "WARNING: Restic backup 'remotebackup' failed on ${config.networking.hostName}!"
              echo ""
            fi
            echo "Backup details"
            echo "=============="
            echo "Host:       ${config.networking.hostName}"
            echo "Backup:     remotebackup"
            echo "Status:     $STATUS"
            echo "Result:     ''${SERVICE_RESULT:-unknown}"
            echo "Exit code:  ''${EXIT_STATUS:-unknown}"
            echo "Repository: sftp://homeassistant/backup/backup_eymeric"
            echo "Paths:      /storage"
            echo ""
            echo "Command output"
            echo "=============="
            printf '%s\n' "$OUTPUT"
          } | ${lib.getExe config.programs.msmtp.package} -t
        '';

        timerConfig = {
          OnCalendar = "00:00";
        };
      };
    };
  };
}
