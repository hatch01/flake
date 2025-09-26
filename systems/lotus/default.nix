# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  username,
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  container.docker.enable = false;
  office.enable = true;
  home-manager.sharedModules = with inputs; [ plasma-manager.homeModules.plasma-manager ];
  ghostwriter.enable = true;

  # dev params
  dev.enable = true;
  jetbrains.enable = false;
  arduino.enable = false;
  dev.androidtools.enable = false;
  vscode.enable = false;

  hm.home.file.".zed_server" = {
    source = "${pkgs.zed-editor.remote_server}/bin";
    recursive = true;
  };

  age = {
    identityPaths = [ "/etc/age/key" ];
  };

  wsl.enable = true;
  wsl.defaultUser = username;
  hm = {
    programs = {
      git = {
        signing = {
          signByDefault = lib.mkForce false;
        };
      };
      zsh = {
        initContent = lib.mkAfter "eval $(${lib.getExe' pkgs.wsl2-ssh-agent "wsl2-ssh-agent"})";
        shellAliases = {
          zeditor = "export ZED_ALLOW_EMULATED_GPU=1; unset WAYLAND_DISPLAY; zeditor";
          ssh = "ssh.exe";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    jira-cli-go
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
