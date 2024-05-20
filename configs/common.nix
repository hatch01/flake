{
  lib,
  config,
  pkgs,
  username,
  stateVersion,
  inputs,
  ...
}: {
  imports = [
    (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" username])
    ./wifi.nix
    ../apps/vm.nix
    ../apps/git.nix
    ../apps/nix-related.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [((import ../overlays) inputs.nixpkgs-unstable)];
  };

  age = {
    identityPaths = ["/etc/age/key"];

    secrets = {
      rootPassword.file = ../secrets/rootPassword.age; # todo change to root password different for each devices
      userPassword.file = ../secrets/userPassword.age;
      githubToken.file = ../secrets/githubToken.age;
    };
  };

  programs.direnv = {
    enable = true;
    loadInNixShell = true;
    nix-direnv.enable = true;
  };

  system.stateVersion = stateVersion;

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

  hm.home = {
    inherit stateVersion username;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment = {
    systemPackages = with pkgs; let
      inherit (pkgs.stdenv.hostPlatform) system;
    in [
      inputs.agenix.packages.${system}.default
      neovim
      wget
      tealdeer
      sbctl
      just
      clang
      killall
      nmap
      openvpn
      nix-index
      nix-output-monitor
      nvd
      openssl
      pv # monitor the progress of data through a pipe
      hyfetch
      zip
      unzip
      file
      which
      tree
      gnupg
      bat
      thefuck
      trash-cli
      btop # replacement of htop/nmon
      iotop # io monitoring
      iftop # network monitoring
      nixpkgs-fmt

      # python is useful
      virtualenv
      (python3.withPackages (ps:
        with ps; [
        ]))
    ];
  };

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

  programs.zsh.enable = true;

  security.sudo.extraConfig = "Defaults targetpw";
  security.sudo.extraRules = [
    {
      users = ["ALL"];
      commands = ["SETENV: ALL"];
    }
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.startAgent = true;

  users.users = {
    "${username}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = ["networkmanager" "vboxusers" "video" "input" "docker"];
      hashedPasswordFile = config.age.secrets.userPassword.path;
    };
    root.hashedPasswordFile = config.age.secrets.rootPassword.path;
  };

  nix.optimise.automatic = true;

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
