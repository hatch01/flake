# stollen here https://astrid.tech/2022/03/05/0/nixos-sp6/
{
  lib,
  config,
  gpuIDs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.vfio.enable =
    mkEnableOption "Configure the machine for VFIO";

  config = mkIf config.vfio.enable {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        # don't know why those modules are not available like in astrid tutorial
        # but it seems to work without them
        #"vfio_virqfd"

        #"nvidia"
        #"nvidia_modeset"
        #"nvidia_uvm"
        #"nvidia_drm"
      ];

      kernelParams = [
        # enable IOMMU
        "amd_iommu=on"
        # isolate the GPU
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)
      ];
    };

    hardware.opengl.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
