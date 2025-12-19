{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cache.onyx.ovh"
      "https://cache.nixos.org"
      "https://cache.nixos-cuda.org"
      "https://nix-community.cachix.org"
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.onyx.ovh:2wUG6wsx5slbKUgkHT6GJuQ5k2StuUc8ysZQ2W+fbxA="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];

    trusted-users = [
      "eymeric"
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/master";
    nixpkgs-stable.url = "nixpkgs/nixos-25.11";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    # nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.url = "github:hatch01/nixos-hardware";

    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    #nur.url = "github:nix-community/NUR";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
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
    flatpaks.url = "github:gmodena/nix-flatpak/?ref=latest";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    impermanence.url = "github:nix-community/impermanence";

    vscode-server = {
      url = "github:hatch01/nixos-vscode-server";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos = {
      url = "github:SaumonNet/proxmox-nixos";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.utils.follows = "flake-utils";
    };

    apolline = {
      url = "git+ssh://git@github.com/hatch01/apolline";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    portfolio = {
      url = "git+ssh://git@github.com/VirisOnGithub/portfolio";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    pikvm = {
      # url = "/home/eymeric/code_bidouille/projet/nixos-pikvm";
      url = "git+https://forge.onyx.ovh/eymeric/nixos-pikvm.git";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixos-hardware.follows = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alesis_midi_converter = {
      url = "git+https://forge.onyx.ovh/eymeric/alesis_midi_converter.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
    };
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        ./systems
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              just
            ];
          };
        };
    };
}
