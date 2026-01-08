{
  stable = [ ];

  unstable = [
    {
      pr = 332296;
      name = "openthread-border-router";
      hash = "sha256-77CKiXwLAK4hgXPMN1lxYcLiWk44Rvs0Tion+t9fB6o=";
    }
  ];

  common = [
    {
      url = "https://github.com/hatch01/nixpkgs/pull/2.diff";
      name = "beszel-disk-systemd";
      hash = "sha256-BA9ofCCEDyVfYI3BnaZvei7f8SHd0PKkW8M/mRJBi7M=";
    }
    {
      pr = 467484;
      name = "sparrow";
      hash = "sha256-Xhica/EuJIoub02lLCHE01FNHr7IlrM1T4Lyq+F3iQo=";
    }
    {
      pr = 477783;
      name = "fzf-zsh";
      hash = "sha256-8dl4VTKRnkePAEPYhhDAy1ryGJFqXpEGkNTeEoeyg/8=";
    }
  ];
}
