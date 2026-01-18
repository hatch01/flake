{
  stable = [
    {
      pr = 477783;
      name = "fzf-zsh";
      hash = "sha256-bYftpEQrSz7I1ozexiVjdOrUuwJxEOsoPFo1tiWi078=";
    }
  ];

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
      hash = "sha256-AE4wxo0FtIZworvbYaUOnoo5uHhwbauRedrk+aolKt4=";
    }
    {
      pr = 467484;
      name = "sparrow";
      hash = "sha256-Xhica/EuJIoub02lLCHE01FNHr7IlrM1T4Lyq+F3iQo=";
    }
  ];
}
