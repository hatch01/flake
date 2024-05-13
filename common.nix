{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  username = "eymeric";
  stateVersion = "23.11";
in {
  imports = [
    (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" username])
    (import ./home.nix
      {
        inherit
          pkgs
          config
          lib
          inputs
          stateVersion
          username
          ;
      })
    ./wifi.nix
    ./apps/vm.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
