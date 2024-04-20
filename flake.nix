{
  description = "Eymeric's NixOS Flake";

  nixConfig = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://cache.nixos.org/" ];
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

  };
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, flatpaks, plasma-manager, nur, lanzaboote, agenix,... }@inputs:
    let
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
	overlays = [ ((import overlays/overlay.nix) pkgs-unstable) ];
    };
  in {
    nixosConfigurations = {
      nixos-eymeric = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs agenix; }; # pretty hacky to pass agenix and inputs to configuration.nix
        inherit system;
	inherit pkgs;
	modules = with inputs; [
	  ./system/configuration.nix
	  ./cachix.nix
	  home-manager.nixosModules.home-manager {
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
}
