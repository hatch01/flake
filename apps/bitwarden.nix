{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options = {
    bitwarden.enable = mkEnableOption "Enable service";

  };

  config = mkIf config.bitwarden.enable {
    environment.systemPackages = with pkgs; [
      bitwarden-desktop
    ];
    programs.zsh.shellInit = "export SSH_AUTH_SOCK=/home/${username}/.bitwarden-ssh-agent.sock";
  };
}
