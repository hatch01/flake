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
            network = {
              device_name = "mautrix-instagram";
              disappear_view_once = false;
              displayname_template = "{{or .DisplayName .Username \"Unknown user\"}} (Insta)";
              location_format = "'https://www.google.com/maps/place/%[1]s,%[2]s'";
              note_to_self_avatar = "mxc://maunium.net/REBIVrqjZwmaWpssCZpBlmlL";
              number_in_topic = true;
              sync_contacts_on_startup = true;
              use_contact_avatars = false;
              use_outdated_profiles = false;
            };
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
            database = {
              type = "postgres";
              uri = "postgresql:///mautrix-meta?host=/run/postgresql";
              max_conn_idle_time = null;
              max_conn_lifetime = null;
              max_idle_conns = 1;
              max_open_conns = 5;
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
