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
      discord = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.discord.enable {
    services.mautrix-discord = {
      enable = true;
      registerToSynapse = true;
      settings = {
        bridge = {
          displayname_template = "{{ or .GlobalName .Username .ID }} (Discord)";
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
            uri = "postgresql:///mautrix-discord?host=/run/postgresql";
          };
        };
      };
      environmentFile = config.age.secrets.matrix_shared_secret.path;
    };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-discord" WITH LOGIN PASSWORD 'discord';
        ALTER ROLE "mautrix-discord" WITH LOGIN;
        CREATE DATABASE "mautrix-discord" WITH OWNER "mautrix-discord"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
