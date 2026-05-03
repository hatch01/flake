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
      let
        isStable = value.stable or false;
      in
      (if isStable then inputs.nixpkgs-stable else inputs.nixpkgs).lib.nixosSystem {
        system = value.system;
        modules = (value.modules isStable) ++ [
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
          stable = isStable;
          system = value.system;
        }
        // (value.specialArgs or { });
      }
    ) systems;
  };

  nixos =
    stable: with inputs; [
      ../configs/common.nix
      disko.nixosModules.disko
      (if stable then home-manager-stable else home-manager).nixosModules.home-manager
      agenix.nixosModules.default
      nix-index-database.nixosModules.nix-index
      impermanence.nixosModules.impermanence
    ];

  server = stable: [ ../configs/server.nix ] ++ (nixos stable);
  desktop = stable: [ ../configs/desktop.nix ] ++ (nixos stable);
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
      stable = true;
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
