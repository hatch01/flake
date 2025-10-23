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
  ]
  ++ lib.optionals (stable) [
    "${inputs.nixpkgs}/nixos/modules/services/monitoring/beszel-hub.nix"
    "${inputs.nixpkgs}/nixos/modules/services/monitoring/beszel-agent.nix"
  ];
}
