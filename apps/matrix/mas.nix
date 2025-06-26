{
  config,
  lib,
  pkgs,
  mkSecret,
  base_domain_name,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  dataDir = "/var/lib/matrix-authentication-service";
  settingsFile = "${dataDir}/settings.yaml";
in {
  imports = [];

  options = {
    matrix.mas = {
      enable = mkEnableOption "enable matrix";
      port = mkOption {
        # currently unused because settings are completly in secret
        type = lib.types.int;
        default = 8081;
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

  config = mkIf config.matrix.mas.enable {
    age.secrets = mkSecret "mas_config" {};

    users = {
      groups.mas = {};
      users.mas = {
        isSystemUser = true;
        group = "mas";
        home = dataDir;
        createHome = true;
        description = "Matrix Authentication Service";
      };
    };

    systemd.services.matrix-authentication-service = {
      enable = true;
      description = "Matrix Authentication Service";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "on-failure";
        EnvironmentFile = config.age.secrets.mas_config.path;
        ExecStart = "${pkgs.matrix-authentication-service}/bin/mas-cli -c ${settingsFile} server";
        User = "mas";
        Group = "mas";
        WorkingDirectory = "${dataDir}";
      };
      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p '${dataDir}'
        test -f '${settingsFile}' && ${pkgs.coreutils}/bin/rm -f '${settingsFile}'
        ${pkgs.envsubst}/bin/envsubst \
          -o '${settingsFile}' \
          -i '${
          (pkgs.writeText "mas-settings.yaml" (lib.generators.toYAML {}
            {
              http = {
                listeners = [
                  {
                    name = "web";
                    resources = [
                      {name = "discovery";}
                      {name = "human";}
                      {name = "oauth";}
                      {name = "compat";}
                      {name = "graphql";}
                      {name = "assets";}
                    ];
                    binds = [
                      {address = "[::]:${toString config.matrix.mas.port}";}
                    ];
                    proxy_protocol = false;
                  }
                  {
                    name = "internal";
                    resources = [
                      {name = "health";}
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
                issuer = "https://${base_domain_name}/";
              };
              database = {
                host = "127.0.0.1";
                port = 5432;
                username = "mas";
                password = "mas";
                database = "mas";
                max_connections = 10;
                min_connections = 0;
                connect_timeout = 30;
                idle_timeout = 600;
                max_lifetime = 1800;
              };
              email = {
                from = "\"Authentication Service\" <root@localhost>";
                reply_to = "\"Authentication Service\" <root@localhost>";
                transport = "blackhole";
              };
              secrets = {
                encryption = "$encryption";
                keys = [
                  {
                    kid = "ERoVDasMln";
                    key = "$ERoVDasMln";
                  }
                  {
                    kid = "Say3DRq9iv";
                    key = "$Say3DRq9iv";
                  }
                  {
                    kid = "g38dzwm5Ug";
                    key = "$g38dzwm5Ug";
                  }
                  {
                    kid = "vIIeN3Ao1A";
                    key = "$vIIeN3Ao1A";
                  }
                ];
              };
              passwords = {
                enabled = false;
              };
              matrix = {
                homeserver = base_domain_name;
                endpoint = "http://[::1]:${toString config.matrix.port}/";
                secret = "$matrix_secret";
              };

              clients = [
                {
                  client_id = "0000000000000000000SYNAPSE";
                  client_auth_method = "client_secret_basic";
                  client_secret = "$client_secret";
                }
              ];

              upstream_oauth2 = {
                providers = [
                  {
                    id = "01H8PKNWKKRPCBW4YGH1RWV279";
                    human_name = "Authelia";
                    issuer = "https://${config.authelia.domain}";
                    client_id = "K4XV9roQMaYIgP8X5dE1iSTEWQlIPSQG64m9OCIdzQgWkEMtYyoOsABGVbMPji-bcuEiBTUI";
                    client_secret = "$provider_client_secret";
                    token_endpoint_auth_method = "client_secret_basic";
                    scope = "openid profile email";
                    discovery_mode = "insecure";
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
            }))
        }'
        ${pkgs.coreutils}/bin/chmod 600 '${settingsFile}'
      '';
    };

    postgres.initialScripts = [
      ''
        CREATE ROLE "mas" WITH LOGIN PASSWORD 'mas';
        ALTER ROLE "mas" WITH LOGIN;
        CREATE DATABASE "mas" WITH OWNER "mas";
      ''
    ];
  };
}
