{
  config,
  lib,
  pkgs,
  mkSecrets,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  puppetFile = "/var/lib/matrix-synapse/puppet.yaml";
  masFile = "/var/lib/matrix-synapse/matrix-authentication-service.yaml";
in
{
  imports = [
    ./signal.nix
    ./discord.nix
    ./whatsapp.nix
    ./mas.nix
    ./instagram.nix
  ];

  options = {
    matrix = {
      enable = mkEnableOption "enable matrix";
      enableElement = mkEnableOption "enable matrix element";
      domain = mkOption {
        type = types.str;
        default = "matrix.${base_domain_name}";
        description = "The domain of the matrix instance";
      };
      port = mkOption {
        type = types.int;
        default = 8008;
      };
    };
  };

  config = mkIf config.matrix.enable {
    matrix.signal.enable = true;
    matrix.whatsapp.enable = true;
    matrix.discord.enable = true;
    matrix.mas.enable = true;
    matrix.instagram.enable = true;

    age.secrets = mkSecrets {
      "matrix_shared_secret" = {
        owner = "matrix-synapse";
      };
    };

    systemd.services.matrix-synapse = {
      serviceConfig = {
        EnvironmentFile = config.age.secrets.matrix_shared_secret.path;
        SystemCallFilter = lib.mkForce [ "@system-service" ]; # making the service less secure to be able to modify files
      };
      preStart = lib.mkBefore ''
          test -f '${puppetFile}' && rm -f '${puppetFile}'
          ${pkgs.envsubst}/bin/envsubst \
              -o '${puppetFile}' \
              -i '${
                (pkgs.writeText "double-puppet.yaml" (
                  lib.generators.toYAML { } {
                    id = "puppet";
                    url = "";
                    as_token = "$SHARED_AS_TOKEN";
                    hs_token = "somethingneveruserwedontcare";
                    sender_localpart = "somethingneveruserwedontcare2";
                    rate_limited = false;
                    namespaces = {
                      users = [
                        {
                          regex = "@.*:onyx\.ovh";
                          exclusive = false;
                        }
                      ];
                    };
                  }
                ))
              }'

        test -f '${masFile}' && rm -f '${masFile}'
          ${pkgs.envsubst}/bin/envsubst \
              -o '${masFile}' \
              -i '${
                (pkgs.writeText "matrix-authentication-service.yaml" (
                  lib.generators.toYAML { } {
                    experimental_features = {
                      msc3861 = {
                        enabled = true;

                        # Synapse will call `{issuer}/.well-known/openid-configuration` to get the OIDC configuration
                        issuer = "https://onyx.ovh/";

                        # Matches the `client_id` in the auth service config
                        client_id = "0000000000000000000SYNAPSE";
                        client_auth_method = "client_secret_basic";
                        # Matches the `client_secret` in the auth service config
                        client_secret = "$client_secret";

                        # Matches the `matrix.secret` in the auth service config
                        admin_token = "$admin_token";

                        # URL to advertise to clients where users can self-manage their account
                        account_management_url = "http=//localhost=8080/account";
                      };
                    };
                  }
                ))
              }'
      '';
    };

    services.matrix-synapse = {
      enable = true;

      extras = [
        "oidc"
      ];

      settings.app_service_config_files = [ puppetFile ];
      extraConfigFiles = [ masFile ];

      settings.server_name = base_domain_name;
      settings.public_baseurl = "https://${config.matrix.domain}";
      settings.listeners = [
        {
          port = config.matrix.port;
          bind_addresses = [ "::1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];
    };
    environment.persistence."/persistent" = {
      directories = [
        {
          directory = "/var/lib/matrix-synapse/media_store/";
          user = "matrix-synapse";
          group = "matrix-synapse";
        }
      ];
    };

    postgres.initialScripts = [
      ''
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE
           = "C";''
    ];
    services.postgresql = {
      ensureUsers = [
        {
          name = "matrix-synapse";
        }
      ];
    };
  };
}
