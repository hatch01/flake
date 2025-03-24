{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    (
      import ../../apps/vfio.nix {
        # RTX 3060
        gpuIDs = [
          "10de:25a5" # Graphics
          "10de:2291" # Audio
        ];
        inherit config lib;
      }
    )
  ];

  ollama.cudaEnabled = false;

  nixpkgs.config.cudaSupport = false;
  environment.systemPackages = with pkgs; [
    cudatoolkit
    nvtopPackages.full
  ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia-container-toolkit.enable = true;
  vfio.enable = true;

  # specialisation = {
  #   "VFIO".configuration = {
  #     system.nixos.tags = ["with-vfio"];
  #     vfio.enable = true;
  #   };

  #   # stollen here https://discourse.nixos.org/t/using-a-low-power-specialisation-for-laptops/22513
  #   disable-GPU.configuration = {
  #     system.nixos.tags = ["disable-GPU"];
  #     environment.etc."specialisation".text = "disable-GPU";
  #     boot.extraModprobeConfig = ''
  #       blacklist nouveau
  #       options nouveau modeset=0
  #     '';

  #     services.udev.extraRules = ''
  #       # Remove NVIDIA USB xHCI Host Controller devices, if present
  #       ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"

  #       # Remove NVIDIA USB Type-C UCSI devices, if present
  #       ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"

  #       # Remove NVIDIA Audio devices, if present
  #       ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"

  #       # Remove NVIDIA VGA/3D controller devices
  #       ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  #     '';
  #     boot.blacklistedKernelModules = ["nouveau" "nvidia" "nvidia_drm" "nvidia_modeset"];

  #     services.xserver.videoDrivers = lib.mkForce ["amdgpu"];
  #     hardware.nvidia-container-toolkit.enable = lib.mkForce false;
  #   };
  # };

  # maybe needed for cuda
  systemd.services.nvidia-control-devices = {
    wantedBy = ["multi-user.target"];
    serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
  };

  # openGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [pkgs.mesa];
  };
  # Load nvidia driver for Xorg and Wayland
  hardware.nvidia = {
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:7:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    #package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
