{
  disko.devices =
    let
      rootDisk = "/dev/sdb";
      dataDisk1 = "/dev/sda";
      dataDisk2 = "/dev/sdc";
    in
    {
      disk = {
        main = {
          device = rootDisk;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "500M";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              swap = {
                size = "16G";
                content = {
                  type = "swap";
                  randomEncryption = true;
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # override existing partition
                  subvolumes = {
                    "/rootfs" = {
                      mountpoint = "/";
                    };
                    "/nix" = {
                      mountOptions = [ "noatime" ];
                      mountpoint = "/nix";
                    };
                    "/persistent" = {
                      # neededForBoot = true;
                      mountpoint = "/persistent";
                    };
                    "/persistent/.snapshots" = {
                      mountpoint = "/persistent/.snapshots";
                    };
                  };
                  mountpoint = "/partition-root";
                };
              };
            };
          };
        };
        data1 = {
          type = "disk";
          device = dataDisk1;
          content = {
            type = "gpt";
            partitions = {
              mirror = {
                size = "500G";
              };
              striped = {
                size = "100%";
              };
            };
          };
        };
        data2 = {
          type = "disk";
          device = dataDisk2;
          content = {
            type = "gpt";
            partitions = {
              mirror = {
                size = "500G";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-d"
                    "raid1"
                    "/dev/disk/by-partlabel/disk-data1-mirror"
                  ];
                  subvolumes = {
                    "/storage" = {
                      mountpoint = "/storage";
                      mountOptions = [
                        "noatime"
                        "compress=zstd:3"
                      ];
                    };
                  };
                };
              };
              striped = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-d"
                    "raid0"
                    "-m"
                    "raid1"
                    "/dev/disk/by-partlabel/disk-data1-striped"
                  ];
                  subvolumes = {
                    "/bitcoin" = {
                      mountpoint = "/storage/bitcoin";
                      mountOptions = [
                        "noatime"
                        "nodatacow"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
}
