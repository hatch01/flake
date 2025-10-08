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
    beszel.hub = {
      enable = mkEnableOption "enable beszel";
      domain = mkOption {
        type = types.str;
        default = "beszel.${base_domain_name}";
        description = "The domain of the beszel instance";
      };
      port = mkOption {
        type = types.int;
        default = 8090;
      };
    };
  };

  config = mkIf config.beszel.hub.enable {
    systemd.services.beszel-hub = {
      serviceConfig = {
        ReadWritePaths = "/storage/beszel";
      };
    };
    services.beszel.hub = {
      enable = true;
      port = config.beszel.hub.port;
      dataDir = "/storage/beszel";
      environment = {
        USER_CREATION = "true";
        DISABLE_PASSWORD_AUTH = "true";
      };
      # environmentFile = ....
    };
  };
}
