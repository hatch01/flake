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
      instagram = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.instagram.enable {
    services.mautrix-meta = {
      instances = {
          instagram = {
            enable = true;
            registerToSynapse = true;
            settings = {
              network.displayname_template = "{{or .DisplayName .Username \"Unknown user\"}}";
              bridge = {
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
                  uri = "postgresql:///mautrix-meta?host=/run/postgresql";
                };
              };
            };
            environmentFile = config.age.secrets.matrix_shared_secret.path;
          };
        };
      };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-meta-instagram" WITH LOGIN PASSWORD 'mautrix-meta-instagram';
        ALTER ROLE "mautrix-meta-instagram" WITH LOGIN;
        CREATE DATABASE "mautrix-meta" WITH OWNER "mautrix-meta-instagram"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";
        CREATE DATABASE "mautrix-meta-instagram" WITH OWNER "mautrix-meta-instagram"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
