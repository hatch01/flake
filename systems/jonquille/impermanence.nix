{
  lib,
  pkgs,
  ...
}:
{
  # Snapper configuration for /persistent backups
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";

    configs = {
      persistent = {
        SUBVOLUME = "/persistent";

        # Unneeded as we use root
        # ALLOW_GROUPS = [ "wheel" ];

        # Rétention : 7 snapshots quotidiens
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = "0";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "0";
        TIMELINE_LIMIT_MONTHLY = "0";
        TIMELINE_LIMIT_YEARLY = "0";
      };
    };
  };

  boot.initrd.systemd = {
    # stollen here : https://github.com/nix-community/impermanence/issues/320#issuecomment-4260870035
    services.impermance-btrfs-rolling-root = {
      description = "Archiving existing BTRFS root subvolume and creating a fresh one";
      # Specify dependencies explicitly
      unitConfig.DefaultDependencies = false;
      # The script needs to run to completion before this service is done
      serviceConfig = {
        Type = "oneshot";
        # to be able to see errors in the script
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
      # This service is required for boot to succeed
      requiredBy = [ "initrd.target" ];
      # Should complete before any file systems are mounted
      before = [ "sysroot.mount" ];

      # Wait until the root device is available
      # If you're altering a different device, specify its device unit explicitly.
      # see: systemd-escape(1)
      requires = [ "initrd-root-device.target" ];
      after = [
        "initrd-root-device.target"
        # Allow hibernation to resume before trying to alter any data
        "local-fs-pre.target"
      ];

      # The body of the script. Make your changes to data here
      script = ''
        mkdir /btrfs_tmp
        mount /dev/disk/by-partlabel/disk-main-root /btrfs_tmp
        if [[ -e /btrfs_tmp/rootfs ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/rootfs)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/rootfs "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +5); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/rootfs
        umount /btrfs_tmp
      '';
    };
    extraBin =
      with pkgs;
      with lib;
      {
        "date" = getExe' coreutils "date";
        "stat" = getExe' coreutils "stat";
        "mv" = getExe' coreutils "mv";
        "find" = getExe findutils;
        "btrfs" = getExe btrfs-progs;
      }; # NOTE: path = [...]; doesnt work for initrd, use full paths in your script or extraBin
  };

  environment.persistence."/persistent" = {
    enable = true;
    directories = [
      {
        directory = "/root/.ssh";
        mode = "0700";
      }
      "/var/lib/systemd/coredump"
      "/etc/nixos"
      "/var/lib/nixos"
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
      }
      "/var/log"
      {
        directory = "/var/lib/acme/";
        user = "acme";
        group = "nginx";
      }
      "/var/lib/tailscale"
      "/var/lib/incus"
      "/var/lib/docker"
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
