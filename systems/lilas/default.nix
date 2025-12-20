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
  ]
  ++ (map (name: ../../apps/${name}) [
    "cockpit.nix"
    "gatus.nix"
    "container.nix"
  ]);

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
  cockpit.domain = "lilas:9090";
  networking.firewall.allowedTCPPorts = [
    config.gatus.port
    config.cockpit.port
  ];

  hardware.enableAllHardware = lib.mkForce false; # needed for sd image creation not crash : https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-2868994145

  services.kvmd = {
    enable = true;
    package = inputs.pikvm.packages.aarch64-linux.default;
    hardwareVersion = "v2-hdmi-rpi4";
    user = "admin";
    passwordFile = config.age.secrets."server/kvmd".path;
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
      "server/kvmd" = {
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
