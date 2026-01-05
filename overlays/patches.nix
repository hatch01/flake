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

    {
      pr = 476595;
      name = "silicon-fix";
      hash = "sha256-IYP/V3D6/T+in2aYYNvAI4tA7NErva0C+BmVk5b5cJg=";
    }
    {
      pr = 476867;
      name = "protoc-fix";
      hash = "sha256-Do+0tzQzLTee5xfC+j868MH/8PqqmWKO4WSmb6AoMAw=";
    }
    {
      pr = 476895;
      name = "anytype-fix";
      hash = "sha256-lBarOU4UZVrcnQdh2CfUE5oJSBgn3kJZJKu44QfZpg8=";
    }
    {
      pr = 477140;
      name = "antares-fix";
      hash = "sha256-E3VkbF0Q2Gj/9Mz+3A3R2l9VDto6VPM17bWcGtl1lhw=";
    }
    {
      pr = 476634;
      name = "epkowa-fix";
      hash = "sha256-YMTJyWYOpzbMyGisjX9BrimX30/ChD+wkc2bHacoS8A=";
    }
    {
      pr = 476347;
      name = "vesktop-fix";
      hash = "sha256-93dNk/7YGrVfgaIZCcDbjNJtyKX9gcv0GQDPgVq1Ji8=";
    }
  ];
}
