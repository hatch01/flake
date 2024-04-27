{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/some-disk-id";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # for example use `echo -n "password" > /tmp/secret.key`
                passwordFile = "/tmp/secret.key";
                settings.allowDiscards = true;
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "10G";
            content = {
              type = "btrfs";
              mountpoint="/";
              subvolumes = {
                "/root" = {
                   mountpoint = "/";
                   mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/nix" = {
                   mountpoint = "/";
                   mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/var" = {
                   mountpoint = "/";
                   mountOptions = [ "compress=zstd" "noatime" "nodatacow" ];
                };

              };
            };
          };
          home = {
            size = "1G";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/home";
            };
          };
          swap = {
              size = "1G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
        };
      };
    };
  };
}

