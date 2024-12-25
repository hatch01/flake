# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  username,
  mkSecret,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [username];
    max-jobs = 2; # how many derivation built at the same time
    cores = 5; # how many cores attributed to one build
  };

  age = {
    secrets = mkSecret "userPassword" {};
  };

  users.users = {
    "${username}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = ["networkmanager" "vboxusers" "video" "input" "docker" "dialout"];
      hashedPasswordFile = config.age.secrets.userPassword.path;
    };
  };

  # Bootloader.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = ["ntfs"];
  boot.binfmt = {
    emulatedSystems = ["aarch64-linux"];
    preferStaticEmulators = true;
  };
  boot.kernelModules = ["v4l2loopback"];
  boot.kernelParams = ["amd_iommu=on"];
  system.nixos.tags = ["tulipe"];
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  programs.ccache.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  hardware.sane.enable = true; # enables support for SANE scanners
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  hardware.sane.extraBackends = [pkgs.epkowa pkgs.utsushi];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
    networkmanager.enable = true;
    nameservers = ["127.0.0.1" "::1"];
    networkmanager.dns = "none";
  };

  services.dnsproxy = {
    enable = true;
    settings = {
      upstream = ["https://dns.onyx.ovh/dns-query"];
      listen-addrs = ["127.0.0.1"];
      # We don't need any bootstrap DNS server because we are setting the ip directly in the hosts section
      # bootstrap = ["9.9.9.9"];
    };
  };
  networking.hosts = {
    "109.26.63.39" = ["dns.onyx.ovh"];
  };

  # Configure console keymap
  console.keyMap = "fr";

  security.rtkit.enable = true;
  security.tpm2.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  virtualisation = {
    waydroid.enable = true;
  };

  environment.systemPackages = with pkgs; [
    openrgb-plugin-hardwaresync
  ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };

  services.udev.packages = with pkgs; [openrgb numworks-udev-rules];

  services.pcscd.enable = true;

  age = {
    identityPaths = ["/etc/age/key"];
  };
}
