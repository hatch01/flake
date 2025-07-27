{
  disko.devices =
    let
      rootDisk = "/dev/mmcblk1";
    in
    {
      disk = {
        main = {
          device = rootDisk;
          type = "disk";
          content = {
            type = "table";
            format = "msdos";
            partitions = [
              {
                label = "PIBOOT";
                type = "primary";
                start = "0";
                end = "256MiB";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              }
              {
                label = "PIPST";
                type = "primary";
                start = "256MiB";
                end = "512MiB";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/var/lib/kvmd/pst";
                  mountOptions = [ "reserved=0" ];
                };
              }
              {
                label = "PIROOT";
                type = "primary";
                start = "512MiB";
                end = "6656MiB";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              }
              {
                label = "PIMSD";
                type = "primary";
                start = "6656MiB";
                end = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/var/lib/kvmd/msd";
                  mountOptions = [ "reserved=0" ];
                };
              }
            ];
          };
        };
      };
    };
}
