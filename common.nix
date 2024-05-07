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
    ./cachix.nix
    ./wifi.nix
    ./apps/vm.nix
    apps/zsh.nix
    apps/keepassxc.nix
    apps/plasma/plasma.nix
    apps/neovim.nix
    apps/onedrive/onedrive.nix
    apps/ghostwriter.nix
    apps/thunderbird.nix
    apps/vscode.nix
    apps/vesktop/vesktop.nix
    #apps/espanso.nix
    apps/konsole.nix
    apps/homebank.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inputs = inputs;
    };
  };

  hm =
    import ./home.nix
    {
      inherit
        pkgs
        config
        lib
        inputs
        stateVersion
        username
        ;
    };
}
