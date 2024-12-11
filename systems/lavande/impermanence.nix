{
  lib,
  config,
  ...
}: let
  inherit (lib) optionals;
in {
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/disk/by-partlabel/disk-main-root /btrfs_tmp

    if [ -e /btrfs_tmp/rootfs ]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date -d "@$(stat -c %Y /btrfs_tmp/rootfs)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/rootfs "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS="\n"
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "$1/$i"
        done
        btrfs subvolume delete "$1"
    }

    num_subvolumes_to_keep=3
    old_subvolumes=$(ls -dt /btrfs_tmp/old_roots/* 2>/dev/null)
    count=0
    for subvolume in $old_subvolumes; do
        count=$((count + 1))
        if [ $count -gt $num_subvolumes_to_keep ]; then
            delete_subvolume_recursively "$subvolume"
        fi
    done

    btrfs subvolume create /btrfs_tmp/rootfs
    umount /btrfs_tmp

  '';

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
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
