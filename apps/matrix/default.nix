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
  oidcFile = "/var/lib/matrix-synapse/matrix-oidc.yaml";
in
{
  imports = [
    ./signal.nix
    ./discord.nix
    ./whatsapp.nix
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

        test -f '${oidcFile}' && rm -f '${oidcFile}'
          ${pkgs.envsubst}/bin/envsubst \
              -o '${oidcFile}' \
              -i '${
                (pkgs.writeText "synapse-oidc.yaml" (
                  lib.generators.toYAML { } {
                    oidc_providers = [
                      {
                        idp_id = "authelia";
                        idp_name = "Authelia";
                        idp_icon = "mxc://authelia.com/cKlrTPsGvlpKxAYeHWJsdVHI";
                        discover = true;
                        issuer = "https://${config.authelia.domain}";
                        client_id = "synapse";
                        client_secret = "$authelia";
                        scopes = [
                          "openid"
                          "profile"
                          "email"
                          "groups"
                        ];
                        allow_existing_users = true;
                        user_mapping_provider = {
                          config = {
                            subject_claim = "sub";
                            localpart_template = "{{ user.preferred_username }}";
                            display_name_template = "{{ user.name }}";
                            email_template = "{{ user.email }}";
                          };
                        };
                        attribute_requirements = [ ];
                        user_profile_method = "userinfo_endpoint";
                      }
                    ];
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
      extraConfigFiles = [ oidcFile ];

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
