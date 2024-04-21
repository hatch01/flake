# treefmt.nix
{pkgs, ...}: {
  # Used to find the project root
  projectRootFile = "flake.nix";
  #projectRootFile = ".git/config";
  #package = pkgs.treefmt;
  #flakeCheck = false; # use pre-commit's check instead
  programs = {
    alejandra.enable = true; # nix
    shellcheck.enable = true;
    shfmt = {
      enable = true;
      indent_size = null;
    };
    prettier.enable = true;
  };
}
