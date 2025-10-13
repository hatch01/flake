{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/choucroute";
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
                name = "encrypted";
                # for example use `echo -n "password" > /tmp/secret.key`
                passwordFile = "/tmp/secret.key";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = [
                    # sudo systemd-cryptenroll /dev/nvme1n1p2 --fido2-device=auto --fido2-with-user-verification=true
                    # sudo systemd-cryptenroll /dev/nvme1n1p2 --wipe-slot=fido2
                    "fido2-device=auto"
                    "token-timeout=10"
                  ];
                };
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
            size = "400G";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/var" = {
                  mountpoint = "/var";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "nodatacow"
                  ];
                };
              };
            };
          };
          home = {
            size = "400G";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/home";
            };
          };
          swap = {
            size = "2G";
            content = {
              type = "swap";
            };
          };
        };
      };
    };
  };
}
