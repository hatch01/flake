{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/mmcblk1";
        type = "disk";
        content = {
          type = "table";
          format = "msdos";
          partitions = [
            {
              name = "PIBOOT";
              part-type = "primary";
              start = "0";
              end = "256MiB";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "PIPST";
              part-type = "primary";
              start = "256MiB";
              end = "512MiB";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/var/lib/kvmd/pst";
                extraArgs = [ "-m" "0" ];
              };
            }
            {
              name = "PIROOT";
              part-type = "primary";
              start = "512MiB";
              end = "6656MiB";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
            {
              name = "PIMSD";
              part-type = "primary";
              start = "6656MiB";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/var/lib/kvmd/msd";
                extraArgs = [ "-m" "0" ];
              };
            }
          ];
        };
      };
    };
  };
}
