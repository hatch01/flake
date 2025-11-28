# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, mkSecrets, ... }:
{
  imports = [
    ./impermanence.nix
  ];

  nextcloud.enable = true;
  nextcloud.app_api.enable = false;
  onlyofficeDocumentServer.enable = true;
  homepage.enable = true;
  authelia.enable = true;
  # gitlab.enable = true;
  forgejo.enable = true;
  beszel.hub.enable = true;
  configUpdater.enable = true;
  nixCache.enable = true;
  adguard.enable = true;
  fail2ban.enable = true;
  cockpit.enable = true;
  matrix.enable = true;
  matrix.enableElement = true;
  watchtower.enable = true;
  ddclient.enable = false;
  home_automation.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;

  librespeed.enable = true;
  apolline.enable = true;
  restic.enable = true;
  portfolio.enable = true;
  incus.enable = true;
  sslh.enable = true;
  wakapi.enable = true;
  vaultwarden.enable = true;

  boot.loader.timeout = 1;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  age = {
    identityPaths = [ "/persistent/key" ];

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

  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub.enable = true;

  services.postgresql.dataDir = "/storage/postgresql/${config.services.postgresql.package.psqlSchema}";

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    oci-containers.backend = "docker";
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
    networkmanager.enable = true;
    hostId = "271e1c23";
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
    groups.smtp = { };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };

  nix.settings = {
    # equals max 10 core for building
    max-jobs = 2;
    cores = 5;
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "03:45" ]; # Optional; allows customizing optimisation schedule

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
