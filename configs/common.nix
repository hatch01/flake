{
  lib,
  config,
  pkgs,
  username,
  stateVersion,
  inputs,
  mkSecrets,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" username ])
    ../apps
  ];

  neovim.enable = true;
  container.enable = true;
  nix-related.enable = true;
  gitConfig.enable = true;
  zshConfig.enable = true;
  beszel.agent.enable = true;
  comin.enable = true;

  nix = {
    package = pkgs.nixVersions.git;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@wheel" ];
      download-buffer-size = 524288000;
    };
  };

  nixpkgs = {
    config = {
      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          # vscode
          "vscode"
          "vscode-extension-github-copilot"
          "vscode-extension-github-copilot-chat"
          "vscode-extension-MS-python-vscode-pylance"
          "vscode-extension-ms-vscode-cpptools"

          # intellij
          "idea"
          "pycharm"
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
          "cudnn"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libnvjitlink"
          "libcusparse"
          "libnpp"
          "libXNVCtrl"
          "blender" # only because of cuda

          # server
          "corefonts"

          "anytype"
          "anytype-heart"
          "nrf-udev"
          "iscan-ds"
          "Oracle_VirtualBox_Extension_Pack"
        ];

      permittedInsecurePackages = [
        "olm-3.2.16"
        "mbedtls-2.28.10"
        "jitsi-meet-1.0.8792"
        "python3.13-ecdsa-0.19.1"
      ];
    };

    overlays = [
      ((import ../overlays/unstable.nix) inputs.nixpkgs-unstable)
      ((import ../overlays/stable.nix) inputs.nixpkgs-stable)
    ];
  };

  age = {
    secrets = mkSecrets {
      rootPassword = { };
      githubToken = {
        root = true;
      };
    };
  };

  programs.direnv = {
    enable = true;
    loadInNixShell = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.nix-index-database.comma.enable = true;

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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    # package = pkgs.lix;
    optimise.automatic = true;
    extraOptions = ''
      !include ${config.age.secrets.githubToken.path}
    '';
    channel.enable = false;
    registry = {
      n.flake = inputs.nixpkgs;
    };
  };

  hm = {
    programs.btop.settings.color_theme = "/home/${username}/.config/btop/themes/catppuccin_mocha.theme";
    home = {
      inherit stateVersion username;
      file.".config/btop/themes" = {
        source =
          pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "btop";
            tag = "1.0.0";
            sha256 = "sha256-J3UezOQMDdxpflGax0rGBF/XMiKqdqZXuX4KMVGTxFk=";
          }
          + "/themes";
      };
    };
  };

  environment = {
    systemPackages =
      with pkgs;
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      [
        inputs.agenix.packages.${system}.default
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
        bat
        trash-cli
        btop # replacement of htop/nmon
        iotop # io monitoring
        nmon
        iftop # network monitoring
        nixfmt
        alejandra
        nixd
        sqlite

        # python is useful
        virtualenv
        poetry
        uv
        (python3.withPackages (ps: [ ]))
      ];
  };
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale.overrideAttrs (oa: {
      doCheck = false;
    });
  };

  security.sudo-rs = {
    enable = true;
    extraConfig = "Defaults targetpw";
    extraRules = [
      {
        users = [ "ALL" ];
        commands = [ "SETENV: ALL" ];
      }
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.rootPassword.path;
      openssh.authorizedKeys.keys = [
        # cockpit ssh key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMD71+kkmmNCsDAtsdB4w3sicLzdJnELExqEIhz3TGEC root@jonquille"

        # ssh-keygen -t ed25519-sk \
        # -O resident \
        # -O verify-required \
        # -O application=ssh:yubi1 \
        # -f ~/.ssh/id_ed25519_sk_rk_yubi1 \
        # -C "eymericdechelette@gmail.com"

        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+QyzHE8xVIWrDHZTf0M8mmFNC1tcbIOt+PafD8H4S7"
      ];
    };
    ${username}.isNormalUser = true; # setting the user to normal user even if for server, the user would be completly empty
  };
}
