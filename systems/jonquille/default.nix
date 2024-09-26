# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  inputs,
  sshPublicKey,
  mkSecrets,
  hostName,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./impermanence.nix
  ];

  # networking.interfaces."eno1".wakeOnLan.policy =
  networking.interfaces."eno1".wakeOnLan.enable = true;
  boot.loader.timeout = 1;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["@wheel"];
  };

  age = {
    identityPaths = ["/persistent/key"];

    secrets = mkSecrets {
      userPassword = {};
      rootPassword = {};
      githubToken = {};
      smtpPassword = {
        group = "smtp";
        mode = "440";
      };
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;
  systemd.services.zfs-mount.enable = false;
  boot.zfs.devNodes = "/dev/disk/by-partuuid"; # TODO only needed in VMs

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    oci-containers.backend = "podman";
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Enable networking
  networking = {
    domain = hostName;
    networkmanager.enable = true;
    hostId = "271e1c23";
    # hosts = {
    #   "127.0.0.1" = [
    #     "${hostName}"
    #     "nextcloud.${hostName}"
    #     "forge.${hostName}"
    #     "authelia.${hostName}"
    #     "matrix.${hostName}"
    #     "dns.${hostName}"
    #   ];
    # };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          sshPublicKey
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@Guillaume-Arch"
        ];
      };
    };
    groups.smtp = {};
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?

  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"]; # Optional; allows customizing optimisation schedule

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
