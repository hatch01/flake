{
  lib,
  config,
  hostName,
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
    cockpit.hostName = mkOption {
      type = lib.types.str;
      default = "cockpit.${hostName}";
      description = "The hostname of the cockpit";
    };
  };

  config = mkIf config.cockpit.enable {
    services.cockpit.enable = true;
    services.cockpit.port = config.cockpit.port;
    services.cockpit.settings = {
      "WebService" = {
        "Origins" = "https://${config.cockpit.hostName} wss://${config.cockpit.hostName}";
        "ProtocolHeader" = "X-Forwarded-Proto";
      };
      #   "basic" = {
      #     "action" = "none";
      #   };
    };
  };
}
