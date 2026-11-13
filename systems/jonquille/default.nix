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
  snapper.enable = true;
  snapper.backups = {
    persistent.path = "/persistent";
    storage.path = "/storage";
  };
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
  cockpit.machines = true;
  cockpit.podman = true;
  matrix.enable = true;
  matrix.enableElement = true;
  matrix.elementCall.enable = true;
  matrix.ketesa.enable = true;
  watchtower.enable = true;
  ddclient.enable = true;
  ddclient.domains = [
    "homeserver.${base_domain_name}"
    base_domain_name
  ];
  home_automation.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;
  nginx.lineageos.enable = true;

  librespeed.enable = true;
  music-assistant.enable = true;
  apolline.enable = true;
  lasuite-meet.enable = false;
  restic.enable = true;
  incus.enable = true;
  sslh.enable = true;
  wakapi.enable = true;
  bitcoin.server.enable = true;
  ntfy.enable = true;
  programs.nh.clean.enable = lib.mkForce false;

  # dev tooling: full neovim via nvchad
  neovim.enable = true;
  neovim.nvchad.enable = true;

  # full zsh for this dev host
  zshConfig.enableFull = true;
  yazi.enable = true;

  nginx.nichihachi.enable = true;
  nginx.nichihachi.backendIp = "192.168.1.124";

  boot.loader.timeout = 1;
  boot.kernelPackages = pkgs.linuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "zbackup" ];
  networking.hostId = "0ff40c1c";
  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly";
    pools = [ "zbackup" ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  age.identityPaths = [ "/persistent/key" ];

  services.mail.sendmailSetuidWrapper.enable = true;

  security.polkit.enable = true;
  services.fwupd.enable = true;

  services.earlyoom.enable = true;

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

  # Define a user account for remote ZFS backups.
  users = {
    mutableUsers = false;
    groups.smtp = { };
    users.guillaume = {
      isNormalUser = true;
      shell = pkgs.bashInteractive;
      home = "/var/empty";
      createHome = false;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@helium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlaMjFhp2adUJa89ylHV+rDLj9xBfhTAF7q+QClqj83 flashonfire@beryllium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBkO8NzZ2DfcwXbrddXhw3gSVZkZcxsFymqNJk6BPSDF root@beryllium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbUVbi9Az9GnBZ5DkSFG418j7o2/iB6Pw6VOGIKrnps flashonfire@bore"
      ];
    };
  };

  services.beszel.agent.environment.EXTRA_FILESYSTEMS =
    "/storage__storage,/boot__boot,/storage/bitcoin__bitcoin";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
    extraConfig =
      let
        zfsBackupWrapper = pkgs.writeShellScript "zfs-backup-wrapper" ''
          set -euo pipefail

          if [ -z "''${SSH_ORIGINAL_COMMAND:-}" ]; then
            echo "Access denied: Interactive login not permitted." >&2
            exit 1
          fi

          read -r -a args <<< "$SSH_ORIGINAL_COMMAND"
          if [ "''${#args[@]}" -eq 0 ]; then
            echo "Access denied: Interactive login not permitted." >&2
            exit 1
          fi

          if [ "''${args[0]}" = "zfs" ]; then
            case "''${args[1]:-}" in
              receive|recv|list|get|rollback|snapshot|destroy|hold|release)
                exec ${pkgs.zfs}/bin/zfs "''${args[@]:1}"
                ;;
              *)
                echo "Access denied: ZFS subcommand not permitted: ''${args[1]:-}" >&2
                exit 1
                ;;
            esac
          elif [ "''${args[0]}" = "ps" ]; then
            exec ${pkgs.procps}/bin/ps "''${args[@]:1}"
          else
            echo "Access denied: Only zfs backup commands are permitted." >&2
            exit 1
          fi
        '';
      in
      ''
        Match User guillaume
            ForceCommand ${zfsBackupWrapper}
            PermitTTY no
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
