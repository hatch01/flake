# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  base_domain_name,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./impermanence.nix
  ];

  apps.ccache.enable = true;
  nextcloud.enable = true;
  nextcloud.app_api.enable = false;
  onlyofficeDocumentServer.enable = true;
  homepage.enable = true;
  authelia.enable = true;
  # gitlab.enable = true;
  anubis.enable = true;
  anubis.services = [ "forgejo" ];
  forgejo.enable = true;
  nixCache.enable = true;
  adguard.enable = true;
  fail2ban.enable = true;
  cockpit.enable = true;
  matrix.enable = true;
  matrix.enableElement = true;
  matrix.elementCall.enable = true;
  watchtower.enable = true;
  ddclient.enable = true;
  ddclient.domains = [
    "homeserver.${base_domain_name}"
    base_domain_name
  ];
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
  bitcoin.server.enable = true;
  ntfy.enable = true;
  programs.nh.clean.enable = lib.mkForce true;

  nginx.nichihachi.enable = false;
  nginx.nichihachi.backendIp = "192.168.1.142";

  boot.loader.timeout = 1;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  age.identityPaths = [ "/persistent/key" ];

  services.mail.sendmailSetuidWrapper.enable = true;

  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable Tailscale routing features for exit node (IP forwarding & sysctl)
  services.tailscale.useRoutingFeatures = "server";

  # btrfs
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/storage" ];
    interval = "weekly";
  };

  # Notifications email pour les scrubs btrfs
  systemd.services."btrfs-scrub-storage-notify" = {
    description = "Send email notification for btrfs scrub on /storage";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.btrfs-progs ];
    script = ''
      if systemctl is-failed "btrfs-scrub-storage.service" >/dev/null 2>&1; then
        STATUS="FAILED"
      else
        STATUS="SUCCESS"
      fi

      SCRUB_STATUS=$(btrfs scrub status /storage 2>&1 || echo "Unable to get scrub status")

      {
        echo "To: root"
        echo "Subject: btrfs scrub $STATUS on /storage"
        echo ""
        echo "btrfs scrub on /storage completed with status: $STATUS"
        echo ""
        echo "Details:"
        echo "$SCRUB_STATUS"
      } | ${lib.getExe config.programs.msmtp.package} -t
    '';
  };

  systemd.services."btrfs-scrub-storage" = {
    unitConfig = {
      OnSuccess = "btrfs-scrub-storage-notify.service";
      OnFailure = "btrfs-scrub-storage-notify.service";
    };
  };

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
  systemd.network.enable = true;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.useNetworkd = true;
  systemd.network.networks."50-enp1s0" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "yes";
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

  # Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    groups.smtp = { };
    users.guillaume = {
      isNormalUser = true;
      shell = "${pkgs.shadow}/bin/nologin";
      home = "/data";
      createHome = false;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@helium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlaMjFhp2adUJa89ylHV+rDLj9xBfhTAF7q+QClqj83 flashonfire@beryllium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBkO8NzZ2DfcwXbrddXhw3gSVZkZcxsFymqNJk6BPSDF root@beryllium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbUVbi9Az9GnBZ5DkSFG418j7o2/iB6Pw6VOGIKrnps flashonfire@bore"
      ];
    };
  };

  # Configure directories for SFTP jailed users.
  # The chroot directory itself must be owned by root and cannot be writable by any user/group.
  # Guillaume can read and write within the 'data' subdirectory.
  systemd.tmpfiles.rules = [
    "d /storage/backup_guillaume 0755 root root - -"
    "d /storage/backup_guillaume/data 0700 guillaume guillaume - -"
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
    extraConfig = ''
      Match User guillaume
          ForceCommand internal-sftp
          ChrootDirectory /storage/backup_guillaume
          PasswordAuthentication no
          AllowTCPForwarding no
          X11Forwarding no
          AllowAgentForwarding no
    '';
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
