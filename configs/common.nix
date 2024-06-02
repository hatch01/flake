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
    ../apps
  ];

  container.enable = true;
  nix-related.enable = true;
  gitConfig.enable = true;
  zshConfig.enable = true;
  # basic-tools.enable = true; # unneeded because it is set to true by default

  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          # vscode
          "vscode"
          "vscode-extension-github-copilot"
          "vscode-extension-github-copilot-chat"
          "vscode-extension-MS-python-vscode-pylance"
          "vscode-extension-ms-vscode-cpptools"

          # intellij
          "idea-ultimate"
          "pycharm-professional"
          "clion"
          "rust-rover"
          "phpstorm"

          # scanner
          "iscan"
          "iscan-gt"
          "iscan-data"
          "iscan-gt-f720-bundle"
          "iscan-nt-bundle"
          "iscan-gt-s650-bundle"
          "iscan-gt-s80-bundle"
          "iscan-v330-bundle"
          "iscan-v370-bundle"
          "iscan-perfection-v550-bundle"
          "iscan-gt-x820-bundle"
          "iscan-gt-x750-bundle"
          "iscan-gt-x770-bundle"

          #gaming
          "steam"
          "steam-run"
          "steam-original"
          "libsciter"
          "parsec-bin"

          #others
          "geogebra"
          "spotify"
          "beeper"
          "skypeforlinux"
          # Nvidia related things
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "cuda-merged"
          "cuda_cuobjdump"
          "cuda_gdb"
          "cuda_nvcc"
          "cuda_nvdisasm"
          "cuda_nvprune"
          "cuda_cccl"
          "cuda_cudart"
          "cuda_cupti"
          "cuda_cuxxfilt"
          "cuda_nvml_dev"
          "cuda_nvrtc"
          "cuda_nvtx"
          "cuda_profiler_api"
          "cuda_sanitizer_api"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libnvjitlink"
          "libcusparse"
          "libnpp"
          "blender" #only because of cuda
      ];
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
      alejandra

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
