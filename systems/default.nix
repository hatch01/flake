{
  inputs,
  lib,
  pkgs,
  ...
}: let
  username = "eymeric";
  stateVersion = "23.11";

  # the shameless borrow loop never stop
  # shamelessly borrowed from uku3lig flake repo
  # shamelessly borrowed from https://github.com/getchoo/flake/blob/94dc521310b34b80158d1a0ab65d4daa3a44d81e/systems/default.nix
  toSystem = builder: name: args:
    (args.builder or builder) (
      (builtins.removeAttrs args ["builder"])
      // {
        modules =
          args.modules
          ++ [
            ./${name}
            ./${name}/hardware-configuration.nix

            {networking.hostName = name;}
          ];
        specialArgs = {inherit inputs username stateVersion;};
      }
    );

  mapNixOS = lib.mapAttrs (toSystem inputs.nixpkgs.lib.nixosSystem);

  nixos = with inputs; [
    ../configs/common.nix
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    nur.nixosModules.nur
  ];

  desktop = with inputs;
    [
      ../configs/desktop.nix
      lanzaboote.nixosModules.lanzaboote
      flatpaks.nixosModules.nix-flatpak
    ]
    ++ nixos;
in {
  flake = {
    nixosConfigurations = mapNixOS {
      tulipe = {
        system = "x86_64-linux";
        modules = desktop;
        specialArgs = {
          inherit inputs;
        };
      };
    };
  };
}
