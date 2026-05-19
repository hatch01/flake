{
  config,
  lib,
  mkSecret,
  base_domain_name,
  pkgs,
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

    # Should not be needed but without this the folder rights are too restrictive and matrix-synapse fail to go inside to read the registration file
    systemd.tmpfiles.rules = [
      "d /var/lib/mautrix-telegram 0775 mautrix-telegram mautrix-telegram -"
    ];

    systemd.services.mautrix-telegram.serviceConfig.EnvironmentFile = [
      config.age.secrets.matrix_shared_secret.path
      config.age.secrets.telegram_credentials.path
    ];
    systemd.services.mautrix-telegram.preStart = ''
      if [ ! -f /var/lib/mautrix-telegram/telegram-registration.yaml ]; then
      ${config.services.mautrix-telegram.package}/bin/mautrix-telegram \
          --generate-registration \
          --config='/var/lib/mautrix-telegram/config.yaml' \
          --registration='/var/lib/mautrix-telegram/telegram-registration.yaml'
      fi
      chmod 640 /var/lib/mautrix-telegram/telegram-registration.yaml

      # 1. Overwrite registration tokens in config
      # 2. Set the double puppeting secret from environment
      ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
          | .[0].appservice.hs_token = .[1].hs_token
          | .[0].network.api_id = (env.MAUTRIX_TELEGRAM_NETWORK__API_ID | tonumber)
          | .[0].network.api_hash = env.MAUTRIX_TELEGRAM_NETWORK__API_HASH
          | .[0]' \
          '/var/lib/mautrix-telegram/config.yaml' '/var/lib/mautrix-telegram/telegram-registration.yaml' > '/var/lib/mautrix-telegram/config.yaml.tmp'
      mv '/var/lib/mautrix-telegram/config.yaml.tmp' '/var/lib/mautrix-telegram/config.yaml'
    '';

    services.mautrix-telegram = {
      enable = true;
      registerToSynapse = true;
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
        appservice = {
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-telegram?host=/run/postgresql";
          };
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
