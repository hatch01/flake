{
  config,
  lib,
  base_domain_name,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
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
            "${base_domain_name}" = "user";
            "@root:${base_domain_name}" = "admin";
          };
          login_shared_secret_map = {
            "${base_domain_name}" = "as_token:$SHARED_AS_TOKEN";
          };
          sync_direct_chat_list = true;
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
          domain = base_domain_name;
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
