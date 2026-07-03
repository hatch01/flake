{
  config,
  lib,
  mkSecrets,
  base_domain_name,
  stable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  credentialPath = name: "/run/credentials/matrix-authentication-service.service/${name}";
in
{
  imports = [ ];

  options = {
    matrix.mas = {
      enable = mkEnableOption "enable matrix";
      port = mkOption {
        type = lib.types.int;
        default = 8089;
        description = "The port on which the MAS will listen";
      };
      port2 = mkOption {
        type = lib.types.int;
        default = 8083;
        description = "The port on which the MAS will listen for internal requests";
      };
      domain = mkOption {
        type = lib.types.str;
        default = "auth.${config.matrix.domain}";
        description = "The domain of the MAS instance";
      };
    };
  };

  config = mkIf config.matrix.mas.enable (
    if !stable then
      {
        age.secrets = mkSecrets {
          "mas_encryption" = { };
          "mas_ERoVDasMln" = { };
          "mas_Say3DRq9iv" = { };
          "mas_g38dzwm5Ug" = { };
          "mas_vIIeN3Ao1A" = { };
          "mas_authelia_secret" = { };
          "mas_matrix_secret" = {
            owner = "matrix-synapse";
            mode = "0440";
          };
        };

        services.matrix-authentication-service = {
          enable = true;
          credentials."matrix_secret" = config.age.secrets.mas_matrix_secret.path;
          credentials."authelia_secret" = config.age.secrets.mas_authelia_secret.path;
          credentials."encryption" = config.age.secrets.mas_encryption.path;
          credentials."ERoVDasMln" = config.age.secrets.mas_ERoVDasMln.path;
          credentials."Say3DRq9iv" = config.age.secrets.mas_Say3DRq9iv.path;
          credentials."g38dzwm5Ug" = config.age.secrets.mas_g38dzwm5Ug.path;
          credentials."vIIeN3Ao1A" = config.age.secrets.mas_vIIeN3Ao1A.path;
          settings = {
            http = {
              listeners = [
                {
                  name = "web";
                  resources = [
                    { name = "discovery"; }
                    { name = "human"; }
                    { name = "oauth"; }
                    { name = "compat"; }
                    { name = "graphql"; }
                    { name = "assets"; }
                  ];
                  binds = [
                    { address = "[::]:${toString config.matrix.mas.port}"; }
                  ];
                  proxy_protocol = false;
                }
                {
                  name = "internal";
                  resources = [
                    { name = "health"; }
                  ];
                  binds = [
                    {
                      host = "localhost";
                      port = config.matrix.mas.port2;
                    }
                  ];
                  proxy_protocol = false;
                }
              ];
              trusted_proxies = [
                "192.168.0.0/16"
                "172.16.0.0/12"
                "10.0.0.0/10"
                "127.0.0.1/8"
                "fd00::/8"
                "::1/128"
              ];
              public_base = "https://${config.matrix.mas.domain}/";
              issuer = "https://${config.matrix.mas.domain}/";
            };
            database = {
              uri = "postgresql://matrix-authentication-service@localhost/mas?host=/run/postgresql";
            };
            email = {
              from = "\"Authentication Service\" <root@localhost>";
              reply_to = "\"Authentication Service\" <root@localhost>";
              transport = "blackhole";
            };
            experimental_features = {
              msc4108_enabled = true;
            };
            passwords = {
              enabled = false;
            };
            matrix = {
              homeserver = base_domain_name;
              endpoint = "http://[::1]:${toString config.matrix.port}/";
              secret_file = credentialPath "matrix_secret";
            };
            upstream_oauth2 = {
              providers = [
                {
                  id = "01H8PKNWKKRPCBW4YGH1RWV279";
                  client_secret_file = credentialPath "authelia_secret";
                  human_name = "Authelia";
                  issuer = "https://${config.authelia.domain}";
                  client_id = "K4XV9roQMaYIgP8X5dE1iSTEWQlIPSQG64m9OCIdzQgWkEMtYyoOsABGVbMPji-bcuEiBTUI";
                  token_endpoint_auth_method = "client_secret_basic";
                  scope = "openid profile email";
                  discovery_mode = "insecure";
                  fetch_userinfo = true;
                  claims_imports = {
                    localpart = {
                      action = "require";
                      template = "{{ user.preferred_username }}";
                    };
                    displayname = {
                      action = "suggest";
                      template = "{{ user.name }}";
                    };
                    email = {
                      action = "suggest";
                      template = "{{ user.email }}";
                      set_email_verification = "always";
                    };
                  };
                }
              ];
            };
            secrets = {
              encryption_file = credentialPath "encryption";
              keys = [
                {
                  kid = "ERoVDasMln";
                  key_file = credentialPath "ERoVDasMln";
                }
                {
                  kid = "Say3DRq9iv";
                  key_file = credentialPath "Say3DRq9iv";
                }
                {
                  kid = "g38dzwm5Ug";
                  key_file = credentialPath "g38dzwm5Ug";
                }
                {
                  kid = "vIIeN3Ao1A";
                  key_file = credentialPath "vIIeN3Ao1A";
                }
              ];
            };
          };
        };

        postgres.initialScripts = [
          ''
            CREATE ROLE "matrix-authentication-service";
            ALTER ROLE "matrix-authentication-service" WITH LOGIN;
            CREATE DATABASE "mas" WITH OWNER "matrix-authentication-service";
          ''
        ];
      }
    else
      { }
  );
}
