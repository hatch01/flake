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
          patches =
            pkgs:
            with pkgs;
            (
              if (value.stable or false) then
                [ ]
              else
                [
                  (fetchpatch2 {
                    name = "openthread-border-router.patch";
                    url = "https://github.com/NixOS/nixpkgs/pull/332296.diff";
                    hash = "sha256-BK/0R3y6KLrMpRgqYAQgmXBrq0DH6K3shHDn/ibzaA8=";
                  })
                  (fetchpatch2 {
                    name = "wsl2-ssh-agent.patch";
                    url = "https://github.com/NixOS/nixpkgs/pull/444409.diff";
                    hash = "sha256-m7WOd5Ski6pVnwHL/FGpJ+IdkW8aJkCYoZTQmotMwh0=";
                  })
                  (fetchpatch2 {
                    name = "beszel-disk.patch";
                    url = "https://github.com/NixOS/nixpkgs/pull/460730.diff";
                    hash = "sha256-1oK/r3biTY3mNuoSRP90KB+MpE8lF2uj1FRhMf7HQtw=";
                  })
                  (fetchpatch2 {
                    name = "beszel-0.16.patch";
                    url = "https://github.com/NixOS/nixpkgs/pull/461325.diff";
                    hash = "sha256-nGJYPEGoNI3RUtMA7A0pD+N/N/Qv+At5Q6CvcQiHl2s=";
                  })

                  (fetchpatch2 {
                   name = "fix-xvideo.patch";
                    url = "https://github.com/NixOS/nixpkgs/pull/461251.diff";
                    hash = "sha256-x3iJ9339vmjW5nYwfeDxrD5jXLqEzZxCx+KloBKxyKk=";
                  })
                  # (fetchpatch2 {
                  #   name = "cockpit.patch";
                  #   url = "https://github.com/NixOS/nixpkgs/pull/447043.diff";
                  #   hash = "sha256-vL4n6/DTr+or5GjAOxrUtEe9UtDXmhwXQ/cUlFfL/Tw=";
                  # })
                ]
            )
            # Common patches for stable and unstable
            ++ [
            ];
        };
        system = value.system;
        modules = value.modules ++ [
          ./${name}
          ./${name}/hardware-configuration.nix
          {
            config.networking = {
              hostName = name;
              domain = value.domain or name;
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
    deploy.nodes = builtins.mapAttrs (name: value: {
      hostname = value.sshAddress or value.domain or name;
      profiles.system = {
        #look at how not to use ssh root login but pass via sudo
        user = value.user or "root";
        sshUser = value.sshUser or "root";
        remoteBuild = value.remoteBuild or true; # think on it if it is a great option
        path = inputs.deploy-rs.lib.${value.system}.activate.nixos inputs.self.nixosConfigurations.${name};
      };
    }) systems;
  };

  nixos = with inputs; [
    ../configs/common.nix
    disko.nixosModules.disko
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    impermanence.nixosModules.impermanence # maybe optimize this because it is not used in all systems
    nix-index-database.nixosModules.nix-index
    #nur.nixosModules.nur
  ];

  server =
    with inputs;
    [
      vscode-server.nixosModules.default
      inputs.proxmox-nixos.nixosModules.proxmox-ve
      ../configs/server.nix
    ]
    ++ nixos;

  desktop =
    with inputs;
    [
      ../configs/desktop.nix
      lanzaboote.nixosModules.lanzaboote
      flatpaks.nixosModules.nix-flatpak
      nixpkgs-xr.nixosModules.nixpkgs-xr
    ]
    ++ nixos;
in
{
  flake = mkSystem {
    tulipe = {
      system = "x86_64-linux";
      modules = desktop;
      domain = "127.0.0.1";
      specialArgs = {
        inherit inputs;
      };
    };
    lotus = {
      system = "x86_64-linux";
      modules = server;
      domain = "127.0.0.1";
      specialArgs = {
        inherit inputs;
      };
    };

    jonquille = {
      system = "x86_64-linux";
      modules = server;
      domain = base_domain_name;
      specialArgs = {
        inherit inputs;
      };
    };
    lavande = {
      system = "aarch64-linux";
      modules = server;
      domain = "129.151.224.5";
      specialArgs = {
        inherit inputs;
      };
    };
    lilas = {
      system = "aarch64-linux";
      modules = server;
      domain = "lilas";
      stable = true;
      specialArgs = {
        inherit inputs;
      };
    };
  };
  # // {checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;};
}
