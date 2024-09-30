{
  inputs,
  lib,
  ...
}: let
  username = "eymeric";
  stateVersion = "24.05";
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs eymericdechelette@gmail.com";
  base_domain_name = "onyx.ovh";

  secretsPath = ../secrets;

  mkSystem = systems: {
    nixosConfigurations = builtins.mapAttrs (name: value:
      inputs.nixpkgs.lib.nixosSystem {
        system = value.system;
        modules =
          value.modules
          ++ [
            ./${name}
            ./${name}/hardware-configuration.nix
            {
              options.hostName = lib.mkOption {
                type = lib.types.str;
                default = toString (value.hostName or name);
              };
              config = {networking.hostName = name;};
            }
          ];
        specialArgs = let
          mkSecrets = builtins.mapAttrs (secretName: secretValue: let
            secretsLocalPath = "${secretsPath}/${
              if (secretValue.root or false)
              then ""
              else "${name}/"
            }";
          in
            lib.removeAttrs secretValue ["root"]
            // {
              file = "${secretsLocalPath}${secretName}.age";
            });
          mkSecret = secretName: other: mkSecrets {${secretName} = other;};
        in
          {
            inherit inputs username stateVersion sshPublicKey mkSecrets mkSecret base_domain_name;
            hostName = value.hostName or name;
          }
          // (value.specialArgs or {});
      })
    systems;
    deploy.nodes =
      builtins.mapAttrs (
        name: value: {
          hostname = value.sshAddress or value.hostName or name;
          profiles.system = {
            #look at how not to use ssh root login but pass via sudo
            user = value.user or "root";
            sshUser = value.sshUser or "root";
            remoteBuild = value.remoteBuild or true; # think on it if it is a great option
            path = inputs.deploy-rs.lib.${value.system}.activate.nixos inputs.self.nixosConfigurations.${name};
          };
        }
      )
      systems;
  };

  nixos = with inputs; [
    ../configs/common.nix
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence # maybe optimize this because it is not used in all systems
    #nur.nixosModules.nur
  ];

  desktop = with inputs;
    [
      ../configs/desktop.nix
      lanzaboote.nixosModules.lanzaboote
      flatpaks.nixosModules.nix-flatpak
    ]
    ++ nixos;
in {
  flake =
    mkSystem {
      tulipe = {
        system = "x86_64-linux";
        modules = desktop;
        hostName = "127.0.0.1";
        specialArgs = {
          inherit inputs;
        };
      };
      jonquille = {
        system = "x86_64-linux";
        modules = nixos;
        sshAddress = "192.168.1.200";
        hostName = "home.onyx.ovh";
        specialArgs = {
          inherit inputs;
        };
      };
      lavande = {
        system = "aarch64-linux";
        modules = nixos;
        hostName = "onyx.ovh";
        specialArgs = {
          inherit inputs;
        };
      };
    }
    // {checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;};
}
