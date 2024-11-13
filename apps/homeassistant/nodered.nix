{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    nodered = {
      enable = mkEnableOption "Home Assistant";
      domain = mkOption {
        type = types.str;
        default = "nodered.${config.networking.domain}";
      };
      port = mkOption {
        type = types.int;
        default = 1880;
      };
    };
  };

  config = mkIf config.nodered.enable {
    environment.persistence."/persistent" = {
      directories = ["/var/lib/node-red"];
    };

    services.node-red = {
      enable = true;
      withNpmAndGcc = true;
      port = config.nodered.port;
    };
  };
}
