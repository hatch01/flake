{
  config,
  lib,
  mkSecret,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    beszel.agent = {
      enable = mkEnableOption "enable beszel";
      port = mkOption {
        type = types.int;
        default = 45876;
      };
    };
  };

  config = mkIf config.beszel.agent.enable {
    services.beszel.agent = {
      enable = true;
      openFirewall = false;
      # extraPath
      environment = {
        PORT = builtins.toString config.beszel.agent.port;
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlwZwhYxzn9RtjWNdPd5raNIa6eQzXCf9994GSRBGjK";
      };
      # environmentFile
    };
  };
}
