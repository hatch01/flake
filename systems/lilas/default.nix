{
  pkgs,
  lib,
  inputs,
  mkSecrets,
  config,
  ...
}:
{
  imports = [
    inputs.pikvm.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    ffmpeg
    i2c-tools
    v4l-utils
    gst_all_1.gstreamer
    dtc
  ];

  container.enable = lib.mkForce false;
  cockpit.enable = true;
  cockpit.domain = "lilas:9090";
  networking.firewall.allowedTCPPorts = [
    config.cockpit.port
  ];

  hardware.enableAllHardware = lib.mkForce false; # needed for sd image creation not crash : https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-2868994145

  services.kvmd = {
    enable = true;
    package = inputs.pikvm.packages.aarch64-linux.default;
    hardwareVersion = "v2-hdmi-rpi4";
    passwordFile = config.age.secrets.kvmd.path;
  };

  security.sudo-rs = {
    enable = lib.mkForce false;
  };

  security.sudo = {
    enable = true;
  };

  age = {
    identityPaths = [ "/etc/age/key" ];

    secrets = mkSecrets {
      kvmd = { };
    };
  };

  boot.loader.timeout = 1;
  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "vfat"
  ];
  boot.kernelParams = [ "boot.shell_on_fail" ];

  # Enable firmware for Raspberry Pi
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = lib.mkForce (
    let
      pkgs_x86 = import inputs.nixpkgs-stable {
        system = "x86_64-linux";
        overlays = [ config.apps.ccache.overlay ];
      };
      crossPkgs = pkgs_x86.pkgsCross.aarch64-multiplatform;
      kernel = crossPkgs.callPackage "${inputs.nixos-hardware}/raspberry-pi/common/kernel.nix" {
        rpiVersion = 4;
      };
      kernelWithCcache = kernel.override {
        stdenv = crossPkgs.ccacheStdenv;
        buildPackages = crossPkgs.buildPackages // {
          stdenv = crossPkgs.buildPackages.ccacheStdenv;
        };
      };
    in
    crossPkgs.linuxPackagesFor kernelWithCcache
  );
}
