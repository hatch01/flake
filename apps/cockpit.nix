{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf;
in {
  options = {
    cockpit.enable = mkEnableOption "Enable cockpit";
    cockpit.port = mkOption {
      type = lib.types.int;
      default = 9090;
      description = "The port of the cockpit";
    };
    cockpit.domain = mkOption {
      type = lib.types.str;
      default = "cockpit.${config.networking.domain}";
      description = "The domain of the cockpit";
    };
  };

  config = mkIf config.cockpit.enable {
    services.cockpit.enable = true;
    services.cockpit.port = config.cockpit.port;
    services.cockpit.allowed-origins = ["https://${config.cockpit.domain}" "wss://${config.cockpit.domain}"];
    services.cockpit.settings = {
      "WebService" = {
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
      };
      #   "basic" = {
      #     "action" = "none";
      #   };
    };
  };
}
