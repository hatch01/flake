{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options = {
    postgres.initialScripts = mkOption {
      type = types.listOf types.str;
      default = "";
      description = ''
        A script to run after the database has been created.
      '';
    };
  };
  config = {
    services.postgresql = {
      initialScript =
        pkgs.writeText "mautrix-signal.sql"
        (lib.concatStrings (config.postgres.initialScripts or []));
      authentication =
        lib.mkIf config.homeassistant.enable
        "host homeassistant_db     homeassistant   172.17.0.1/16      md5 # Home Assistant server";
      enableTCPIP = config.homeassistant.enable;
    };
  };
}
