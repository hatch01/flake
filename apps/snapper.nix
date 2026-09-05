{ lib, config, pkgs, username, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf;

  # Base keep-strategy for every snapshot config.
  # Any of these can be overridden per-backup simply by adding the key.
  baseSettings = {
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "24";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "4";
    TIMELINE_LIMIT_MONTHLY = "12";
    TIMELINE_LIMIT_YEARLY = "10";
  };
in
{
  options.snapper = {
    enable = mkEnableOption "snapper with timeline backups";

    snapshotInterval = mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "Interval at which snapshots are created.";
    };

    cleanupInterval = mkOption {
      type = lib.types.str;
      default = "1h";
      description = "Interval at which old snapshots are cleaned up.";
    };

    setupQuota = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable btrfs qgroups so the used-space display and any space-aware
        cleanup of snapper work. If you set QGROUP in a backup, its
        space-aware cleanup needs this too.
      '';
    };

    backups = mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Snapshot configs to set up, one per subvolume. Each key is the
        snapper config name; each value needs a `path` attribute and can
        override any base keep-strategy setting.
      '';
    };
  };

  config = mkIf config.snapper.enable (
    let
      mkConfig =
        name: backup:
        {
          SUBVOLUME =
            backup.path
            or (throw "snapper.backups.${name} requires a `path` attribute.");
        }
        // baseSettings
        // lib.removeAttrs backup [ "path" ];
    in
    {
      services.snapper = {
        snapshotInterval = config.snapper.snapshotInterval;
        cleanupInterval = config.snapper.cleanupInterval;
        configs = lib.mapAttrs mkConfig config.snapper.backups;
      };

      systemd.services.snapper-setup-quota = mkIf config.snapper.setupQuota {
        description = "Enable btrfs quota for snapper";
        after = [ "local-fs.target" ];
        requires = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.btrfs-progs ];
        script = let
          mountpaths = lib.unique (
            map (backup: backup.path) (lib.attrValues config.snapper.backups)
          );
        in
          ''
            set -eu
          '' + lib.concatMapStringsSep "\n" (path: ''
            if ! btrfs qgroup show "${path}" > /dev/null 2>&1; then
              btrfs quota enable "${path}"
            fi
          '') mountpaths;
      };
    }
  );
}
