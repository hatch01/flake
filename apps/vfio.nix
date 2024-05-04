# stollen here https://astrid.tech/2022/03/05/0/nixos-sp6/
let
  # RTX 3060
  gpuIDs = [
    "10de:25a5" # Graphics
    "10de:2291" # Audio
  ];
in
  {
    lib,
    config,
    ...
  }: {
    options.vfio.enable = with lib;
      mkEnableOption "Configure the machine for VFIO";

    config = let
      cfg = config.vfio;
    in {
      boot = {
        initrd.kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
          #"vfio_virqfd"

          #"nvidia"
          #"nvidia_modeset"
          #"nvidia_uvm"
          #"nvidia_drm"
        ];

        kernelParams =
          [
            # enable IOMMU
            "amd_iommu=on"
          ]
          ++ lib.optional cfg.enable
          # isolate the GPU
          ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
      };

      hardware.opengl.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
    };
  }
