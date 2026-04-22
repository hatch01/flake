{
  config,
  lib,
  stable,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
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
      environment = {
        PORT = toString config.beszel.agent.port;
        KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlwZwhYxzn9RtjWNdPd5raNIa6eQzXCf9994GSRBGjK";
      };
    }
    // optionalAttrs (!stable) {
      smartmon.enable = true;
    };
  };
}
