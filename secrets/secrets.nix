let
  eymeric = "age1aq7l5msnq4leddht4sr3sm56v9qu408r94txwyutvz690tlxmdjss9lm94";

  all = [eymeric];
in {
  "userPassword.age".publicKeys = all;
  "rootPassword.age".publicKeys = all;
  "githubToken.age".publicKeys = all;
}
