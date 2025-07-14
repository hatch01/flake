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
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.pikvm.nixosModules.default
  ];

  container.enable = lib.mkForce false;
  gatus.enable = true;
  cockpit.enable = true;
  networking.firewall.allowedTCPPorts = [config.gatus.port config.cockpit.port];

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
    identityPaths = ["/etc/age/key"];

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

  # Basic system configuration for Raspberry Pi 4

  # Nginx reverse proxy for kvmd Unix socket
  services.nginx = {
    enable = true;
    virtualHosts."lilas" = {
      listen = [
        { addr = "0.0.0.0"; port = 80; }
      ];
      locations."/" = {
        proxyPass = "http://unix:/run/kvmd/kvmd.sock";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };

  # Disable ZFS to avoid the build error
  # boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.loader.timeout = 1;
  boot.supportedFilesystems = lib.mkForce ["ext4" "vfat"];
  boot.kernelParams = ["boot.shell_on_fail"];

  # Basic bootloader configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Use latest kernel packages as in your configuration
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable firmware for Raspberry Pi
  hardware.enableRedistributableFirmware = true;
}
