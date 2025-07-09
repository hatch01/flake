{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    substituters = [
      "https://cache.onyx.ovh"
      "https://cache.nixos.org"
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
      # "https://cache.saumon.network/proxmox-nixos"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.onyx.ovh:2wUG6wsx5slbKUgkHT6GJuQ5k2StuUc8ysZQ2W+fbxA="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "proxmox-nixos:nveXDuVVhFDRFx8Dn19f1WDEaNRJjPrF2CPD2D+m1ys="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    trusted-users = [
      "eymeric"
    ];
  };

  inputs = {
    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-25.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    #nur.url = "github:nix-community/NUR";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.pre-commit-hooks-nix.follows = "";
      inputs.flake-compat.follows = "";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:hatch01/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flatpaks.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # treefmt-nix.url = "github:numtide/treefmt-nix";
    # pre-commit-hooks-nix = {
    #   url = "github:cachix/pre-commit-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    deploy-rs.url = "github:serokell/deploy-rs";
    impermanence.url = "github:nix-community/impermanence";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    apolline.url = "git+ssh://git@github.com/hatch01/apolline";
    portfolio.url = "git+ssh://git@github.com/VirisOnGithub/portfolio";
    polypresence = {
      url = "git+ssh://git@github.com/Eclairsombre/PolyPresence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pikvm = {
      url = "/home/eymeric/tmp/nixos-pikvm"; 
      # url = "git+https://forge.onyx.ovh/eymeric/nixos-pikvm.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    foodi = {
      url = "git+https://forge.onyx.ovh/eymeric/foodi.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };
  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        # inputs.pre-commit-hooks-nix.flakeModule
        # inputs.treefmt-nix.flakeModule
        ./systems
      ];

      perSystem = {pkgs, ...}: {
        # # Auto formatters. This also adds a flake check to ensure that the
        # # source tree was auto formatted.
        # treefmt.config = {
        #   projectRootFile = ".git/config";
        #   package = pkgs.treefmt;
        #   flakeCheck = false; # use pre-commit's check instead
        #   programs = {
        #     alejandra.enable = true;
        #     shellcheck.enable = false;
        #     shfmt = {
        #       indent_size = null;
        #     };
        #     prettier.enable = true;
        #   };
        # };

        # pre-commit = {
        #   check.enable = true;
        #   settings.hooks = {
        #     ripsecrets = {
        #       enable = true;
        #     };
        #     treefmt.enable = true;
        #     typos.enable = false;
        #   };
        # };
        devShells.default = pkgs.mkShell {
          # Inherit all of the pre-commit hooks.
          # inputsFrom = [config.pre-commit.devShell];
          buildInputs = with pkgs; [pkgs.deploy-rs just alejandra];
        };
      };
    };
}
