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
        analytics = {
          token = null;
          url = "https://api.segment.io/v1/track";
          user_id = null;
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
        network = {
          device_name = "mautrix-signal";
          disappear_view_once = false;
          displayname_template = "{{or .ContactName \" Unknown user \"}} (Signal)";
          location_format = "'https://www.google.com/maps/place/%[1]s,%[2]s'";
          note_to_self_avatar = "mxc://maunium.net/REBIVrqjZwmaWpssCZpBlmlL";
          number_in_topic = true;
          sync_contacts_on_startup = true;
          use_contact_avatars = false;
          use_outdated_profiles = false;
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
          domain = base_domain_name;
        };
        appservice = {
          address = "https://localhost:29328";
          async_transactions = false;
          bot.avatar = "mxc://maunium.net/wPJgTQbZOtpBFmDNkiNEMDUp";
        };
        database = {
          type = "postgres";
          uri = "postgresql:///mautrix-signal?host=/run/postgresql";
          max_conn_idle_time = null;
          max_conn_lifetime = null;
          max_idle_conns = 1;
          max_open_conns = 5;
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
