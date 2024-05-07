{inputs, ...}: {
  flake = {
    nixosConfigurations = {
      nixos-eymeric = let
        system = "x86_64-linux";
        pkgs = import inputs.nixpkgs {
          inherit system;
          config = {
            cudaSupport = true;
            allowUnfree = true;
          };
          overlays = [((import ./overlays) inputs.nixpkgs-unstable)];
        };
      in
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            agenix = inputs.agenix;
            inherit inputs;
          };
          inherit system pkgs;
          modules = [
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.agenix.nixosModules.default
            inputs.nur.nixosModules.nur

            ./disk.nix
            {_module.args.disks = ["/dev/nvme0n1"];}
            ./common.nix #{inherit inputs;}
            ./system/configuration.nix
          ];
        };
    };
  };
}
