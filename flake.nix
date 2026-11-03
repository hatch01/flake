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
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.onyx.ovh:2wUG6wsx5slbKUgkHT6GJuQ5k2StuUc8ysZQ2W+fbxA="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    trusted-users = [ "eymeric" ];
    extra-sandbox-paths = [ "/var/cache/ccache" ];
  };

  inputs = {
    nixpkgs.url = "https://forge.onyx.ovh/eymeric/nixpkgs-patched/archive/nixos-unstable.tar.gz";
    nixpkgs-stable.url = "https://forge.onyx.ovh/eymeric/nixpkgs-patched/archive/nixos-stable.tar.gz";
    nixos-wsl = {
      url = "https://forge.onyx.ovh/github_mirror/NixOS-WSL/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    nixos-hardware = {
      url = "https://forge.onyx.ovh/github_mirror/nixos-hardware/archive/master.tar.gz";
      # url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems.url = "https://forge.onyx.ovh/github_mirror/nix-systems/archive/main.tar.gz";

    flake-parts = {
      url = "https://forge.onyx.ovh/github_mirror/flake-parts/archive/main.tar.gz";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "https://forge.onyx.ovh/github_mirror/lanzaboote/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "https://forge.onyx.ovh/github_mirror/disko/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "https://forge.onyx.ovh/github_mirror/agenix/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "https://forge.onyx.ovh/github_mirror/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "https://forge.onyx.ovh/github_mirror/home-manager/archive/release-26.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    plasma-manager = {
      url = "https://forge.onyx.ovh/github_mirror/plasma-manager/archive/trunk.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    impermanence.url = "https://forge.onyx.ovh/github_mirror/impermanence/archive/master.tar.gz";

    apolline = {
      # dépôt privé : l'archive HTTPS demanderait un token, on garde git+ssh
      url = "git+ssh://forgejo@forge.onyx.ovh:443/eymeric/apolline.git";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "https://forge.onyx.ovh/github_mirror/nix4nvchad/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pikvm = {
      # url = "/home/eymeric/code_bidouille/projet/nixos-pikvm";
      url = "https://forge.onyx.ovh/eymeric/nixos-pikvm/archive/main.tar.gz";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixos-hardware.follows = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-index-database = {
      url = "https://forge.onyx.ovh/github_mirror/nix-index-database/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alesis_midi_converter = {
      url = "https://forge.onyx.ovh/eymeric/alesis_midi_converter/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bass2midi = {
      url = "https://forge.onyx.ovh/eymeric/bass2midi/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "https://forge.onyx.ovh/github_mirror/musnix/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "https://forge.onyx.ovh/github_mirror/comin/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "https://forge.onyx.ovh/github_mirror/flake-utils/archive/main.tar.gz";
      inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "https://forge.onyx.ovh/github_mirror/flake-compat/archive/master.tar.gz";
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
