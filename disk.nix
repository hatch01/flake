{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme1n1";
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
            size = "50G";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/var" = {
                  mountpoint = "/var";
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
            size = "16G";
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

