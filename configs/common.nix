{
  lib,
  config,
  pkgs,
  username,
  stateVersion,
  inputs,
  mkSecrets,
  sshPublicKey,
  ...
}: {
  imports = [
    (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" username])
    ../apps
    ../modules
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
          "datagrip"

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
          "iscan-gt-s600-bundle"

          #gaming
          "steam"
          "steam-run"
          "steam-unwrapped"
          "steam-original"
          "libsciter"
          "parsec-bin"

          #others
          "geogebra"
          "spotify"
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
          "libXNVCtrl"
          "blender" #only because of cuda

          # server
          "corefonts"

          "anytype"
          "anytype-heart"
        ];

      permittedInsecurePackages = [
        "olm-3.2.16"
      ];
    };

    overlays = [
      ((import ../overlays/unstable.nix) inputs.nixpkgs-unstable)
      ((import ../overlays/stable.nix) inputs.nixpkgs-stable)
      (final: prev: {
        kalker = prev.callPackage ../overlays/kalker.nix {};
      })
    ];
  };

  age = {
    secrets = mkSecrets {
      rootPassword = {};
      githubToken = {root = true;};
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
    backupFileExtension = "backup";
  };

  nix = {
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    # package = pkgs.lix;
    optimise.automatic = true;
    extraOptions = ''
      !include ${config.age.secrets.githubToken.path}
    '';
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
      nixfmt-rfc-style
      alejandra
      nixd
      sqlite

      # python is useful
      virtualenv
      poetry
      uv
      (python3.withPackages (ps: []))
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

  services.tailscale.enable = true;

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
    root = {
      hashedPasswordFile = config.age.secrets.rootPassword.path;
      openssh.authorizedKeys.keys = [
        sshPublicKey
        # cockpit ssh key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMD71+kkmmNCsDAtsdB4w3sicLzdJnELExqEIhz3TGEC root@jonquille"
      ];
    };
    ${username}.isNormalUser = true; # setting the user to normal user even if for server, the user would be completly empty
  };
}
