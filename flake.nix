{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    substituters = [
      "https://cache.nixos.org/"
      "https://cache.garnix.io"
    ];
    trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
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

    nur.url = "github:nix-community/NUR";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:uku3lig/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.agenix.inputs.darwin.follows = "";
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

    treefmt-nix.url = "github:numtide/treefmt-nix";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    flake-parts,
    nixpkgs,
    systems,
    nixpkgs-unstable,
    home-manager,
    flatpaks,
    plasma-manager,
    nur,
    lanzaboote,
    disko,
    agenix,
    treefmt-nix,
    pre-commit-hooks-nix,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [
        pre-commit-hooks-nix.flakeModule
        treefmt-nix.flakeModule
      ];

      flake = {
        nixosConfigurations = {
          nixos-eymeric = let
            system = "x86_64-linux";

            pkgs = import nixpkgs {
              inherit system;
              config = {
                cudaSupport = true;
                allowUnfree = true;
              };
              overlays = [((import ./overlays) nixpkgs-unstable)];
            };
          in
            nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit inputs agenix;
              };
              inherit system pkgs;
              modules = [
                disko.nixosModules.disko
                ./disk.nix
                {_module.args.disks = ["/dev/nvme0n1"];}
                ./system/configuration.nix
                ./cachix.nix
                ./wifi.nix
                ./apps/vm.nix
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {
                    inherit inputs;
                  };
                  home-manager.users.eymeric = import ./home.nix;
                }
                lanzaboote.nixosModules.lanzaboote
                agenix.nixosModules.default
              ];
            };
        };
      };

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Auto formatters. This also adds a flake check to ensure that the
        # source tree was auto formatted.
        treefmt.config = {
          projectRootFile = ".git/config";
          package = pkgs.treefmt;
          flakeCheck = false; # use pre-commit's check instead
          programs = {
            alejandra.enable = true; # nix
            shellcheck.enable = true;
            shfmt = {
              enable = true;
              indent_size = null;
            };
            prettier.enable = true;
          };
        };

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            editorconfig-checker = {
              enable = true;
              excludes = [
                ".*\\.age"
              ];
            };
            ripsecrets = {
              enable = true;
            };
            treefmt.enable = true;
            typos = {
              enable = true;
            };
          };
        };
        devShells.default = pkgs.mkShell {
          # Inherit all of the pre-commit hooks.
          inputsFrom = [config.pre-commit.devShell];
        };
      };
    };
}
