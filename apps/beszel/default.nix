{
  inputs,
  lib,
  stable,
  ...
}:
{
  imports = [
    ./hub.nix
    ./agent.nix
  ];
}
