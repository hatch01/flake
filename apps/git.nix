{
  pkgs,
  lib,
  config,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    gitConfig.enable = mkEnableOption "Enable git configuration";
  };
  config = mkIf config.gitConfig.enable {
    environment.systemPackages = with pkgs; [
      delta
      nodePackages.ungit
      lazygit
    ];
    programs.git.enable = true;

    hm = {
      programs = {
        git = {
          enable = true;
          userName = username;
          userEmail = "eymericdechelette@gmail.com";
          signing = {
            key = "/home/${username}/.ssh/yubikey.pub";
            signByDefault = true;
            format = "ssh";
          };
          extraConfig = {
            pull.rebase = true;
            safe.directory = [
              "/etc/nixos/.git"
              "/etc/nixos"
            ];
            merge.conflictstyle = "zdiff3";
            merge.tool = "vimdiff";
            core.pager = "delta";
            interactive.diffFilter = "delta --color-only";
            delta = {
              navigate = true;
              dark = true;
              side-by-side = true;
            };
            diff.colorMoved = "default";
            rebase.autoStash = true;
            merge.autoStash = true;
            status.showStash = true;
            push.autoSetupRemote = true;
          };
          aliases = {
            tree = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
          };
        };
        gh = {
          enable = true;
          settings.git_protocol = "ssh";
        };
      };
    };
  };
}
