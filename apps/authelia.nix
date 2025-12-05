{
  lib,
  config,
  mkSecrets,
  pkgs,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    optionals
    types
    ;
  autheliaInstance = "main";
  mkUserRule =
    {
      appName,
      two_factor ? true,
      groups ? [ ],
    }:
    optionals config."${appName}".enable [
      {
        domain = config."${appName}".domain;
        policy = if two_factor then "two_factor" else "one_factor";
        subject = builtins.concatLists (map (group: [ [ "group:${group}" ] ]) groups);
      }
    ];
in
{
  options = {
    authelia = {
      enable = mkEnableOption "enable Authelia";
      domain = mkOption {
        type = types.str;
        default = "authelia.${base_domain_name}";
        description = "The domain of the Authelia instance";
      };
      port = mkOption {
        type = types.int;
        default = 9091;
        description = "The port on which Authelia will listen";
      };
    };
  };

  config = mkIf config.authelia.enable {
    age.secrets =
      let
        cfg = {
          owner = "authelia";
          group = "authelia";
        };
      in
      mkSecrets {
        "authelia/storageKey" = cfg;
        "authelia/jwtKey" = cfg;
        "authelia/authBackend" = cfg;
        "authelia/oAuth2PrivateKey" = cfg;
        "authelia/oAuth2HmacSecret" = cfg;
      };
    users = {
      users.authelia = {
        isSystemUser = true;
        group = "authelia";
        extraGroups = [ "smtp" ];
      };
      groups.authelia = { };
    };

    systemd.services.authelia = {
      after = [ "postgresql.service" ];
    };
    systemd.services."authelia-${autheliaInstance}" = {
      environment = {
        # needed to set the secrets using agenix see: https://www.authelia.com/configuration/methods/files/#file-filters
        X_AUTHELIA_CONFIG_FILTERS = "template";
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets."server/smtpPassword".path;
      };
    };

    services = {
      authelia.instances = {
        "${autheliaInstance}" = {
          enable = true;
          package = pkgs.authelia;
          user = "authelia";
          group = "authelia";

          secrets = {
            storageEncryptionKeyFile = config.age.secrets."authelia/storageKey".path;
            jwtSecretFile = config.age.secrets."authelia/jwtKey".path;
            oidcHmacSecretFile = config.age.secrets."authelia/oAuth2HmacSecret".path;
            oidcIssuerPrivateKeyFile = config.age.secrets."authelia/oAuth2PrivateKey".path;
          };

          settings = {
            theme = "auto";

            default_2fa_method = "webauthn";
            webauthn = {
              disable = false;
              display_name = "Authelia";
              attestation_conveyance_preference = "indirect";
              timeout = "60s";
              selection_criteria.user_verification = "preferred";
            };

            regulation = {
              max_retries = 3;
              find_time = "2m";
              ban_time = "5m";
            };

            totp = {
              disable = false;
              issuer = base_domain_name;
              algorithm = "sha512";
              digits = 6;
              period = 30;
              skew = 1;
              secret_size = 32;
              allowed_algorithms = [
                "SHA512"
                "SHA256"
                "SHA1"
              ];
              allowed_digits = [ 6 ];
              allowed_periods = [ 30 ];
              disable_reuse_security_policy = false;
            };

            # TODO add duo configuration later

            server = {
              disable_healthcheck = true;
              address = "tcp://:${toString config.authelia.port}/";
              endpoints = {
                authz = {
                  auth-request = {
                    implementation = "AuthRequest";
                  };
                };
              };
            };
            log = {
              format = "text"; # for fail2ban better integration
              file_path = "/var/lib/authelia-main/authelia.log";
              keep_stdout = true;
              level = "info";
            };
            storage = {
              postgres = {
                address = "/run/postgresql";
                database = "authelia";
                username = "authelia";
                password = "anUnus3dP@ssw0rd"; # thanks copilot for this beautiful password
              };
            };

            # notifier needed for 2FA and email
            # https://www.authelia.com/configuration/notifications/introduction/
            notifier = {
              disable_startup_check = true;
              smtp = {
                # using 587 port which is unencrypted I know but did not manage to make it working with 465
                # however this is very not probable that someone will sniff the network
                address = "smtp://smtp.free.fr:587";
                timeout = "60s";
                username = "eymeric.monitoring";
                sender = "Authelia <authelia@onyx.ovh>";
                subject = "[Authelia] {title}";
                startup_check_address = "eymericdechelette@gmail.com";
                disable_require_tls = false;
                disable_starttls = false;
                disable_html_emails = false;
              };
            };

            access_control = {
              default_policy = "deny";
              networks = [
                {
                  name = "internal";
                  networks = [ "127.0.0.1/32" ];
                }
              ];
              rules = [
                # be careful with the order of the rules it is important
                # https://www.authelia.com/configuration/security/access-control/#rule-matching
                {
                  domain_regex = ".*\.${base_domain_name}";
                  policy = "bypass";
                  networks = [ "internal" ];
                }
                {
                  domain_regex = ".*\.${base_domain_name}";
                  policy = "two_factor";
                  subject = [
                    [ "group:admin" ]
                  ];
                }
              ]
              ++ mkUserRule {
                appName = "homepage";
                two_factor = false;
              }
              ++ mkUserRule {
                appName = "librespeed";
              }
              ++ mkUserRule {
                appName = "nodered";
                groups = [ "home" ];
              }
              ++ mkUserRule {
                appName = "zigbee2mqtt";
                groups = [ "home" ];
              }
              ++ mkUserRule {
                appName = "esp_home";
                groups = [ "home" ];
              }
              ++ mkUserRule {
                appName = "apolline";
                two_factor = false;
              };
            };

            authentication_backend = {
              password_reset.disable = true;
              password_change.disable = true;
              file = {
                # a agenix managed yaml doc : https://www.authelia.com/reference/guides/passwords/#yaml-format
                path = config.age.secrets."authelia/authBackend".path;
                # letting password hashing settings to the default (argon2id)
              };
            };

            session = {
              cookies = [
                {
                  domain = base_domain_name;
                  authelia_url = "https://${config.authelia.domain}";
                  default_redirection_url = "https://${base_domain_name}";
                }
              ];
            };

            identity_providers.oidc = {
              # enable to make it working so using settingsFiles (look above)
              # jwks = [
              #   {
              #     key_id = "main";
              #     key = ''{{ secret "${config.age.secrets."authelia/oAuth2PrivateKey".path}" | mindent 10 "|" | msquote }}'';
              #   }
              # ];
              claims_policies = {
                grafana.id_token = [
                  "email"
                  "name"
                  "groups"
                  "preferred_username"
                ];

              };
              clients =
                [ ]
                ++ optionals config.nextcloud.enable [
                  {
                    client_name = "NextCloud";
                    client_id = "nextcloud";
                    # the client secret is a random hash so don't worry about it
                    client_secret = "$pbkdf2-sha512$310000$NqCsT52TLWKH2GOq1c7vyw$ObxsUBEcwK53BY8obKj7fjmk1xp4MnTYCc2kS9UKpKifVGOQczt4rQx0bWt5pInqpAKxGHXo/RGa7DolDugz2A";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    redirect_uris = [ "https://${config.nextcloud.domain}/apps/oidc_login/oidc" ];
                    scopes = [
                      "openid"
                      "profile"
                      "email"
                      "groups"
                    ];
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ]
                ++ optionals config.forgejo.enable [
                  {
                    client_name = "ForgeJo";
                    client_id = "forgejo";
                    # the client secret is a random hash so don't worry about it
                    client_secret = "$pbkdf2-sha512$310000$EZtlQ4D8vOBPYNwxDbNk.w$oD6J/PyDotGjOUjq2uLaDpdO.uAVX3LpSvQgxD.q.G9FS8JQ5CKhx3j8HPdJlV2Gt2Pmvo/P0dpsX01Cic3A/g";
                    public = false;
                    authorization_policy = "two_factor";
                    redirect_uris = [ "https://${config.forgejo.domain}/user/oauth2/authelia/callback" ];
                    scopes = [
                      "openid"
                      "email"
                      "profile"
                    ];
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ]
                ++ optionals config.matrix.mas.enable [
                  {
                    client_name = "Matrix";
                    client_id = "K4XV9roQMaYIgP8X5dE1iSTEWQlIPSQG64m9OCIdzQgWkEMtYyoOsABGVbMPji-bcuEiBTUI";
                    # the client secret is a random hash so don't worry about it
                    client_secret = "$pbkdf2-sha512$310000$XVZ/KKrIuhfG7m/bnQXEHQ$/cHzLB6xyflth5HKJWR/Lc.//j4S/YiJ6lSaEH.rmskegD6c4zdgbni1Q.yfZrdRBg13.E8MGSyw4X1KpECv7Q";
                    public = false;
                    authorization_policy = "two_factor";
                    redirect_uris = [
                      "https://${config.matrix.mas.domain}/upstream/callback/01H8PKNWKKRPCBW4YGH1RWV279"
                    ];
                    scopes = [
                      "openid"
                      "groups"
                      "profile"
                      "email"
                      "offline_access"
                    ];
                    grant_types = [
                      "refresh_token"
                      "authorization_code"
                    ];
                    response_types = [ "code" ];
                  }
                ]
                ++ optionals config.proxmox.enable [
                  {
                    client_name = "Proxmox";
                    client_id = "proxmox";
                    client_secret = "$pbkdf2-sha512$310000$e/dFI8VC5Zerk6OiaJgp3A$N1PK2UNbf3XAnlF0aIufRZJB//X6vkn.VjwiGerc3bmyI.TkzPHWWm40r2cTGXU3/hTxRcApEJk5uK4tTDGuIA";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                    redirect_uris = [ "https://${config.proxmox.domain}" ];
                    scopes = [
                      "openid"
                      "profile"
                      "email"
                    ];
                  }
                ]
                ++ optionals config.influxdb.grafana.enable [
                  {
                    client_id = "grafana";
                    claims_policy = "grafana";
                    client_name = "Grafana";
                    client_secret = "$pbkdf2-sha512$310000$qxL5kiQdjtage4ccg4zvhw$zRW7z7OS7rCDGwEWgKm5WcY.wLrJ31sONLfqIDE5fLfS9fELCna38kBCsr6g8U6CqSlhl.l6ylqYp8cLBRD/Ig";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    redirect_uris = [ "https://${config.influxdb.grafana.domain}/login/generic_oauth" ];
                    scopes = [
                      "openid"
                      "profile"
                      "groups"
                      "email"
                    ];
                    response_types = [ "code" ];
                    grant_types = [ "authorization_code" ];
                    access_token_signed_response_alg = "none";
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ]
                ++ optionals config.incus.enable [
                  {
                    client_id = "incus";
                    client_name = "Incus";
                    public = true;
                    authorization_policy = "two_factor";
                    redirect_uris = [
                      "https://incus.onyx.ovh/oidc/callback"
                      "https://${config.incus.domain}/iodc/callback"
                    ];
                    audience = [
                      "https://${config.incus.domain}"
                    ];
                    scopes = [
                      "openid"
                      "offline_access"
                    ];
                    grant_types = [
                      "refresh_token"
                      "authorization_code"
                    ];
                    access_token_signed_response_alg = "RS256";
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "none";
                  }
                ]
                ++ optionals config.beszel.hub.enable [
                  {
                    client_id = "beszel";
                    client_name = "Beszel";
                    client_secret = "$pbkdf2-sha512$310000$a5eI50mjNqSpsIt4zWbXPw$W9.fVZBp6QqyhVJMCQbRFbSuGGzHZf/.kWP0NcjtVORXGOs4BPbWPfW7x/kYyW8dk/Pj9kzb9j4sOZ6KV.9pZQ";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    redirect_uris = [
                      "https://${config.beszel.hub.domain}/api/oauth2-redirect"
                    ];
                    scopes = [
                      "openid"
                      "email"
                      "profile"
                    ];
                    response_types = [
                      "code"
                    ];
                    grant_types = [
                      "authorization_code"
                    ];
                    access_token_signed_response_alg = "none";
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ];
            };
          };
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = [ "authelia" ];
        ensureUsers = [
          {
            name = "authelia";
            ensureDBOwnership = true;
          }
        ];
      };
    };
  };
}
