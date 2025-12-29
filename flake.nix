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
    nixpkgs.url = "git+https://forge.onyx.ovh/github_mirror/nixpkgs?shallow=1&ref=nixos-unstable";
    nixpkgs-unstable.url = "git+https://forge.onyx.ovh/github_mirror/nixpkgs?shallow=1&ref=master";
    nixpkgs-stable.url = "git+https://forge.onyx.ovh/github_mirror/nixpkgs?shallow=1&ref=nixos-25.11";
    nixos-wsl = {
      url = "git+https://forge.onyx.ovh/github_mirror/NixOS-WSL?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    nixos-hardware.url = "git+https://forge.onyx.ovh/github_mirror/nixos-hardware?shallow=1";

    systems.url = "git+https://forge.onyx.ovh/github_mirror/nix-systems?shallow=1";

    flake-parts = {
      url = "git+https://forge.onyx.ovh/github_mirror/flake-parts?shallow=1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "git+https://forge.onyx.ovh/github_mirror/lanzaboote?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://forge.onyx.ovh/github_mirror/disko?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "git+https://forge.onyx.ovh/github_mirror/agenix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "git+https://forge.onyx.ovh/github_mirror/home-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "git+https://forge.onyx.ovh/github_mirror/plasma-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    impermanence.url = "git+https://forge.onyx.ovh/github_mirror/impermanence?shallow=1";

    apolline = {
      url = "git+ssh://forgejo@forge.onyx.ovh/eymeric/apolline.git";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    portfolio = {
      url = "git+ssh://forgejo@forge.onyx.ovh/github_mirror/portfolio?shallow=1";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "git+https://forge.onyx.ovh/github_mirror/nix4nvchad?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    pikvm = {
      # url = "/home/eymeric/code_bidouille/projet/nixos-pikvm";
      url = "git+https://forge.onyx.ovh/eymeric/nixos-pikvm.git?shallow=1";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixos-hardware.follows = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-patcher.url = "git+https://forge.onyx.ovh/github_mirror/nixpkgs-patcher?shallow=1";

    nix-index-database = {
      url = "git+https://forge.onyx.ovh/github_mirror/nix-index-database?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alesis_midi_converter = {
      url = "git+https://forge.onyx.ovh/eymeric/alesis_midi_converter.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "git+https://forge.onyx.ovh/github_mirror/comin?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "git+https://forge.onyx.ovh/github_mirror/flake-utils?shallow=1";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "git+https://forge.onyx.ovh/github_mirror/flake-compat?shallow=1";
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
