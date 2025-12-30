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
      hash = "sha256-2w9LHL3eQTQrandBmE/HywfFaHJTHk7g/mr+PmCXl7A=";
    }
    {
      pr = 467484;
      name = "sparrow";
      hash = "sha256-Xhica/EuJIoub02lLCHE01FNHr7IlrM1T4Lyq+F3iQo=";
    }
  ];
}
