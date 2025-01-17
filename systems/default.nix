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
    nixosConfigurations = builtins.mapAttrs (name: value: let
      nixpkgs =
        if value.stable or false
        then inputs.nixpkgs-stable
        else inputs.nixpkgs;
    in
      nixpkgs.lib.nixosSystem {
        system = value.system;
        modules =
          value.modules
          ++ [
            ./${name}
            ./${name}/hardware-configuration.nix
            {
              config.networking = {
                hostName = name;
                domain = value.domain or name;
              };
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
            stable = value.stable or false;
            system = value.system;
          }
          // (value.specialArgs or {});
      })
    systems;
    deploy.nodes =
      builtins.mapAttrs (
        name: value: {
          hostname = value.sshAddress or value.domain or name;
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

  server = with inputs;
    [
      vscode-server.nixosModules.default
      inputs.proxmox-nixos.nixosModules.proxmox-ve
      ../configs/server.nix
    ]
    ++ nixos;

  desktop = with inputs;
    [
      ../configs/desktop.nix
      lanzaboote.nixosModules.lanzaboote
      flatpaks.nixosModules.nix-flatpak
    ]
    ++ nixos;
in {
  flake = mkSystem {
    tulipe = {
      system = "x86_64-linux";
      modules = desktop;
      domain = "127.0.0.1";
      specialArgs = {
        inherit inputs;
      };
    };
    jonquille = {
      system = "x86_64-linux";
      modules = server;
      domain = "onyx.ovh";
      specialArgs = {
        inherit inputs;
      };
    };
  };
  # // {checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;};
}
