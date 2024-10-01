# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  inputs,
  mkSecrets,
  ...
}: {
  imports = [
    ./impermanence.nix
  ];

  nextcloud.enable = true;
  onlyofficeDocumentServer.enable = true;
  homepage.enable = true;
  authelia.enable = true;
  gitlab.enable = true;
  netdata.enable = true;
  nixCache.enable = true;
  adguard.enable = true;
  fail2ban.enable = true;
  matrix.enable = true;
  matrix.enableElement = true;
  ddclient.enable = false;
  watchtower.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;

  adguard.hostName = "dns.${config.hostName}";
  gitlab.hostName = "forge.${config.hostName}";

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
      "server/smtpPassword" = {
        group = "smtp";
        mode = "440";
        root = true;
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
    domain = config.networking.hostName;
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

  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"]; # Optional; allows customizing optimisation schedule

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
