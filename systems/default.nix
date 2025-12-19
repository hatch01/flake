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

                  # (fetchpatch2 {
                  #   name = "cockpit.patch";
                  #   url = "https://github.com/NixOS/nixpkgs/pull/447043.diff";
                  #   hash = "sha256-vL4n6/DTr+or5GjAOxrUtEe9UtDXmhwXQ/cUlFfL/Tw=";
                  # })
                ]
            )
            # Common patches for stable and unstable
            ++ [
              (fetchpatch2 {
                name = "cockpit-zfs.patch";
                url = "https://github.com/hatch01/nixpkgs/pull/5.diff";
                hash = "sha256-h2gy/AJsMNIMBOQ+PJlajun//aPY+1oMJtNqzWd8iVw=";
              })
              # Beszel
              (fetchpatch2 {
                name = "beszel-disk-systemd.patch";
                url = "https://github.com/hatch01/nixpkgs/pull/2.diff";
                hash = "sha256-2w9LHL3eQTQrandBmE/HywfFaHJTHk7g/mr+PmCXl7A=";
              })
            ];
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
    impermanence.nixosModules.impermanence # maybe optimize this because it is not used in all systems
    nix-index-database.nixosModules.nix-index
    #nur.nixosModules.nur
  ];

  server =
    with inputs;
    [
      vscode-server.nixosModules.default
      ../configs/server.nix
    ]
    ++ nixos;

  desktop =
    with inputs;
    [
      ../configs/desktop.nix
      lanzaboote.nixosModules.lanzaboote
      flatpaks.nixosModules.nix-flatpak
    ]
    ++ nixos;
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
  # // {checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;};
}
