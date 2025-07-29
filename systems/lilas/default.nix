# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
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
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
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
  gatus.enable = true;
  cockpit.enable = true;
  networking.firewall.allowedTCPPorts = [
    config.gatus.port
    config.cockpit.port
  ];

  hardware.enableAllHardware = lib.mkForce false; # needed for sd image creation not crash : https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-2868994145

  services.kvmd = {
    enable = true;
    package = inputs.pikvm.packages.aarch64-linux.default;
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
      "server/smtpPassword" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
      "server/smtpPasswordEnv" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
    };
  };

  # Disable ZFS to avoid the build error
  # boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.loader.timeout = 1;
  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "vfat"
  ];
  boot.kernelParams = [ "boot.shell_on_fail" ];

  # Enable firmware for Raspberry Pi
  hardware.enableRedistributableFirmware = true;
}
