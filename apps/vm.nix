{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    vm.enable = mkEnableOption "Enable virtualisation support";
  };

  config = mkIf config.vm.enable {
    # Enable dconf (System Management Tool)
    programs.dconf.enable = true;
    programs.virt-manager.enable = true;

    # Add user to libvirtd group
    users.users.${username}.extraGroups = ["libvirtd"];

    # Install necessary packages
    environment.systemPackages = with pkgs; [
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
      virglrenderer
      quickemu
      gnome-boxes
    ];

    users.extraGroups.vboxusers.members = ["eymeric"];

    # Manage the virtualisation services
    virtualisation = {
      virtualbox = {
        host = {
          enable = true;
          #          enableExtensionPack = true;
        };
      };

      libvirtd = {
        enable = true;
        qemu = {
          ovmf.enable = true;
          swtpm.enable = true;
          ovmf.packages = [
            pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd # AAVMF
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            })
            .fd
          ];
          runAsRoot = false;
        };
      };
      spiceUSBRedirection.enable = true;
    };
    services.spice-vdagentd.enable = true;
    services.qemuGuest.enable = true;
  };
}
