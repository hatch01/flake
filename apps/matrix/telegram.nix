{
  config,
  lib,
  mkSecret,
  base_domain_name,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    matrix = {
      telegram = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.telegram.enable {
    age.secrets = mkSecret "telegram_credentials" { };

    systemd.services.mautrix-telegram.restartTriggers = [
      config.age.secrets.matrix_shared_secret.file
      config.age.secrets.telegram_credentials.file
    ];

    services.mautrix.bridges.telegram = {
      type = "telegram";
      enable = true;
      registerToSynapse = true;
      environmentFiles = [
        config.age.secrets.matrix_shared_secret.path
        config.age.secrets.telegram_credentials.path
      ];
      settings = {
        bridge = {
          displayname_template = "{{ or .FirstName .LastName .Username \"Unknown user\" }} (Telegram)";
          permissions = {
            "*" = "relay";
            "${base_domain_name}" = "user";
            "@root:${base_domain_name}" = "admin";
          };
          sync_direct_chat_list = true;
        };
        double_puppet = {
          secrets = {
            "${base_domain_name}" = "as_token:$SHARED_AS_TOKEN";
          };
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
          domain = base_domain_name;
        };
        encryption = {
          require = false;
          msc4190 = true;
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-telegram?host=/run/postgresql";
        };
      };
    };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-telegram" WITH LOGIN PASSWORD 'telegram';
        ALTER ROLE "mautrix-telegram" WITH LOGIN;
        CREATE DATABASE "mautrix-telegram" WITH OWNER "mautrix-telegram"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
