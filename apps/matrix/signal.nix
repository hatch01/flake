{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    matrix = {
      signal = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.signal.enable {
    services.mautrix-signal = {
      enable = true;
      registerToSynapse = true;
      settings = {
        bridge = {
          displayname_template = "{{or .ContactName \"Unknown user\"}} (Signal)";
          permissions = {
            "*" = "relay";
            "${config.networking.domain}" = "user";
            "@root:${config.networking.domain}" = "admin";
          };
          login_shared_secret_map = {
            "${config.networking.domain}" = "as_token:$SHARED_AS_TOKEN";
          };
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
          domain = config.networking.domain;
        };
        appservice = {
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-signal?host=/run/postgresql";
          };
        };
      };
      environmentFile = config.age.secrets.matrix_shared_secret.path;
    };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-signal" WITH LOGIN PASSWORD 'signal';
        ALTER ROLE "mautrix-signal" WITH LOGIN;
        CREATE DATABASE "mautrix-signal" WITH OWNER "mautrix-signal"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
