{pkgs, ...}: {
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
        userName = "eymeric";
        userEmail = "eymericdechelette@gmail.com";
        signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs";
        signing.signByDefault = true;
        extraConfig = {
          pull.rebase = true;
          safe.directory = "/etc/nixos";
          merge.conflictstyle = "diff3";
          merge.tool = "vimdiff";
          gpg.format = "ssh";
          core.pager = "delta";
          interactive.diffFilter = "delta --color-only";
          delta.navigate = true;
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
}
