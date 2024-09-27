{
  inputs,
  lib,
  ...
}: let
  username = "eymeric";
  stateVersion = "24.05";
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs eymericdechelette@gmail.com";

  secretsPath = ../secrets;
  mkSecrets = builtins.mapAttrs (name: value: value // {file = "${secretsPath}/${name}.age";});
  mkSecret = name: other: mkSecrets {${name} = other;};

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
        specialArgs =
          {inherit inputs username stateVersion sshPublicKey mkSecrets mkSecret;}
          // (value.specialArgs or {})
          // {hostName = value.hostName or name;};
      })
    systems;
    deploy.nodes =
      builtins.mapAttrs (
        name: value: {
          hostname = value.hostName or name;
          profiles.system = {
            #look at how not to use ssh root login but pass via sudo
            user = value.user or "root";
            sshUser = value.sshUser or "root";
            remoteBuild = value.remoteBuild or true; # think on it if it is a great option
            # autoRollback = false;
            # magicRollback = false;
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
        specialArgs = {
          inherit inputs;
        };
      };
      # jonquille = {
      #   system = "x86_64-linux";
      #   modules = nixos;
      #   hostName = "home.onyx.ovh";
      #   specialArgs = {
      #     inherit inputs;
      #   };
      # };
      # lavande = {
      #   system = "arm64-linux";
      #   modules = nixos;
      #   hostName = "onyx.ovh";
      #   specialArgs = {
      #     inherit inputs;
      #   };
      # };
    }
    // {checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;};
}
