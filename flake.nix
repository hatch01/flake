{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://hatch01.cachix.org"
      "https://numtide.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      # "https://cache.onyx.ovh"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.onyx.ovh:2wUG6wsx5slbKUgkHT6GJuQ5k2StuUc8ysZQ2W+fbxA="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "hatch01.cachix.org-1:MiLD2xTBHcs0zIYozmA//rR+/svETz0AXzDFmI2Wjso="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    trusted-users = [
      "eymeric"
    ];
  };

  inputs = {
    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";

    systems.url = "github:nix-systems/default";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    #nur.url = "github:nix-community/NUR";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:hatch01/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flatpaks.url = "github:gmodena/nix-flatpak/?ref=v0.2.0";

    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";

    # treefmt-nix.url = "github:numtide/treefmt-nix";
    # pre-commit-hooks-nix = {
    #   url = "github:cachix/pre-commit-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    deploy-rs.url = "github:serokell/deploy-rs";

    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        # inputs.pre-commit-hooks-nix.flakeModule
        # inputs.treefmt-nix.flakeModule
        ./systems
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
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
