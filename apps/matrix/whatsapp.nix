{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    matrix = {
      whatsapp = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.whatsapp.enable {
    systemd.services.matrix-synapse.serviceConfig.SupplementaryGroups = ["mautrix-whatsapp"];
    services.matrix-synapse.settings.app_service_config_files = [
      # "/var/lib/mautrix-whatsapp/whatsapp-registration.yaml"
    ];
    services.mautrix-whatsapp = {
      enable = true;
      settings = {
        bridge = {
          permissions = {
            "*" = "relay";
            "${config.hostName}" = "user";
            "@root:${config.hostName}" = "admin";
          };
          login_shared_secret_map = {
            "${config.hostName}" = "as_token:$SHARED_AS_TOKEN";
          };
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
        };
        appservice = {
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
          };
        };
      };
      environmentFile = config.age.secrets.matrix_shared_secret.path;
    };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-whatsapp" WITH LOGIN PASSWORD 'whatsapp';
        ALTER ROLE "mautrix-whatsapp" WITH LOGIN;
        CREATE DATABASE "mautrix-whatsapp" WITH OWNER "mautrix-whatsapp"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
