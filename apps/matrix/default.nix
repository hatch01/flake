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
    ./element-call.nix
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
      "matrix_signing_key" = {
        owner = "matrix-synapse";
      };
      "mas_matrix_secret" = { };
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
      '';
    };

    services.matrix-synapse = {
      enable = true;

      settings = {
        app_service_config_files = [ puppetFile ];

        matrix_authentication_service = {
          enabled = true;
          endpoint = "http://[::1]:${toString config.matrix.mas.port}/";
          secret_path = config.age.secrets.mas_matrix_secret.path;
        };

        server_name = base_domain_name;
        public_baseurl = "https://${config.matrix.domain}";
        listeners = [
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
        experimental_features = {
          msc3266_enabled = true;
          msc4222_enabled = true;
        };
        max_event_delay_duration = "24h";
        rc_message = {
          per_second = 0.5;
          burst_count = 30;
        };
        rc_delayed_event_mgmt = {
          per_second = 1;
          burst_count = 20;
        };
        signing_key_path = config.age.secrets.matrix_signing_key.path;
      };
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
