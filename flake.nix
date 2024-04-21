{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = ["nix-command" "flakes"];
    substituters = ["https://cache.nixos.org/"];
  };

  inputs = {
    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    nur.url = github:nix-community/NUR;

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
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
      url = github:cachix/pre-commit-hooks.nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    systems,
    nixpkgs-unstable,
    home-manager,
    flatpaks,
    plasma-manager,
    nur,
    lanzaboote,
    agenix,
    treefmt-nix,
    pre-commit-hooks-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = {
        cudaSupport = true;
        allowUnfree = true;
      };
    };
    pkgs = import nixpkgs {
      inherit system;
      config = {
        cudaSupport = true;
        allowUnfree = true;
      };
      overlays = [((import overlays/overlay.nix) pkgs-unstable)];
    };
    # Small tool to iterate over each systems
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

    # Eval the treefmt modules from ./treefmt.nix
    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    nixosConfigurations = {
      nixos-eymeric = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs agenix;}; # pretty hacky to pass agenix and inputs to configuration.nix
        inherit system pkgs;
        modules = with inputs; [
          ./system/configuration.nix
          ./cachix.nix
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
    # for `nix fmt`
    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
    # for `nix flake check`
    checks = eachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });

    pre-commit = {
      check.enable = true;
      settings.hooks = {
        editorconfig-checker = {
          enable = true;
          excludes = [
            ".*\\.age"
            ".*\\.gpg"
          ];
        };
        ripsecrets = {
          enable = true;
          excludes = [".*\\.crypt"];
        };
        treefmt.enable = true;
        typos = {
          enable = true;
          excludes = [".*\\.crypt"];
        };
      };
    };
  };
}
