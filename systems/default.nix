{
  inputs,
  lib,
  ...
}:
let
  username = "eymeric";
  stateVersion = "24.05";
  base_domain_name = "onyx.ovh";

  secretsPath = ../secrets;

  mkSystem = systems: {
    nixosConfigurations = builtins.mapAttrs (
      name: value:
      inputs.nixpkgs-patcher.lib.nixosSystem {
        nixpkgsPatcher = {
          nixpkgs = if (value.stable or false) then inputs.nixpkgs-stable else inputs.nixpkgs;
          enable = true;
          patches = import ../overlays/patches.nix (value.stable or false);
        };
        system = value.system;
        modules = value.modules ++ [
          ./${name}
          ./${name}/hardware-configuration.nix
          {
            config.networking = {
              hostName = name;
              domain = name;
            };
          }
        ];
        specialArgs = rec {
          inherit
            inputs
            username
            stateVersion
            base_domain_name
            ;
          mkSecrets = builtins.mapAttrs (
            secretName: secretValue:
            lib.removeAttrs secretValue [ "root" ]
            // {
              file = "${secretsPath}/${if (secretValue.root or false) then "" else "${name}/"}${secretName}.age";
            }
          );
          mkSecret = secretName: other: mkSecrets { ${secretName} = other; };
          stable = value.stable or false;
          system = value.system;
        }
        // (value.specialArgs or { });
      }
    ) systems;
  };

  nixos = with inputs; [
    ../configs/common.nix
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    nix-index-database.nixosModules.nix-index
    impermanence.nixosModules.impermanence
  ];
  server = [ ../configs/server.nix ] ++ nixos;
  desktop = [ ../configs/desktop.nix ] ++ nixos;
in
{
  flake = mkSystem {
    tulipe = {
      system = "x86_64-linux";
      modules = desktop;
      specialArgs = { inherit inputs; };
    };
    lotus = {
      system = "x86_64-linux";
      modules = server;
      specialArgs = { inherit inputs; };
    };

    jonquille = {
      system = "x86_64-linux";
      modules = server;
      specialArgs = { inherit inputs; };
    };
    cyclamen = {
      system = "x86_64-linux";
      modules = server;
      specialArgs = { inherit inputs; };
    };
    lilas = {
      system = "aarch64-linux";
      modules = server;
      stable = true;
      specialArgs = { inherit inputs; };
    };
  };
}
