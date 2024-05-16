# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  inputs,
  agenix,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../apps/vfio.nix
    ../apps/gaming.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    max-jobs = 2; # how many derivation built at the same time
    cores = 5; # how many cores attributed to one build
  };
  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
  # Bootloader.
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.supportedFilesystems = ["ntfs"];
  boot.kernelModules = ["v4l2loopback"];
  boot.kernelParams = ["amd_iommu=on"];
  system.nixos.tags = ["tulipe"];
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  networking.hostName = "nixos-eymeric"; # Define your hostname.

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

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  age = {
    identityPaths = ["/etc/age/key"];

    secrets = {
      rootPassword.file = ../secrets/rootPassword.age;
      userPassword.file = ../secrets/userPassword.age;
      githubToken.file = ../secrets/githubToken.age;
    };
  };

  # power management

  powerManagement.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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
  services = {
    displayManager = {
      defaultSession = "plasma";
      autoLogin = {
        enable = true;
        user = "eymeric";
      };
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "fr";
        variant = "";
      };
      displayManager = {
        lightdm.enable = true;
      };
      videoDrivers = ["nvidia"];
    };
    desktopManager.plasma6.enable = true;
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable sound with pipewire.
  sound.enable = true;

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
    docker = {
      enable = true;
      storageDriver = "btrfs";
      enableNvidia = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    wget
    tealdeer
    sbctl
    just
    clang
    killall
    pv
    nmap
    pinentry
    partition-manager
    libsForQt5.kpmcore
    openvpn
    glxinfo
    openrgb-with-all-plugins
    openrgb-plugin-effects
    openrgb-plugin-hardwaresync
    docker-compose
    podman-compose
    cudatoolkit
    nix-index
    nh
    nix-output-monitor
    nvd
    agenix.packages.${system}.default
    age
    openssl
    appimage-run
  ];
  services.udev.packages = [pkgs.openrgb];
  services.onedrive.enable = true;
  environment.plasma6.excludePackages = with pkgs.libsForQt5; [
    elisa
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # change sudo behavior to ask root password everytime
  security.sudo.extraConfig = "Defaults targetpw";
  security.sudo.extraRules = [
    {
      users = ["ALL"];
      commands = ["SETENV: ALL"];
    }
  ];

  services.flatpak.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        set shiftwidth=2
      '';
    };
  };
  programs.git = {
    enable = true;
    config = {
      user.name = "eymeric";
      user.email = "eymericdechelette@gmail.com";
      pull.rebase = true;
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs";
      signing.signByDefault = true;
      gpg.format = "ssh";
    };
  };

  programs.nix-ld.enable = true;

  environment.variables.EDITOR = "nvim";
  environment.pathsToLink = ["/share/zsh"];
  programs.zsh.enable = true;
  users.users = {
    eymeric = {
      isNormalUser = true;
      description = "eymeric";
      extraGroups = ["networkmanager" "vboxusers" "video" "input" "docker"];
      hashedPasswordFile = config.age.secrets.userPassword.path;
      shell = pkgs.zsh;
    };
    root.hashedPasswordFile = config.age.secrets.rootPassword.path;
  };

  nix.optimise.automatic = true;
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
  };
}
