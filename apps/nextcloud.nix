{
  config,
  mkSecrets,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types optionalAttrs optionals;
in {
  options = {
    nextcloud = {
      enable = mkEnableOption "Nextcloud";
      domain = mkOption {
        type = types.str;
        default = "nextcloud.${config.networking.domain}";
      };
      port = mkOption {
        type = types.int;
        default = 443;
      };
    };
    onlyofficeDocumentServer = {
      enable = mkEnableOption "OnlyOffice document server";
      domain = mkOption {
        type = types.str;
        default = "onlyoffice.${config.networking.domain}";
      };
      port = mkOption {
        type = types.int;
        default = 8000;
      };
    };
  };

  config = {
    age.secrets =
      optionalAttrs config.nextcloud.enable (mkSecrets {
        nextcloudAdmin = {
          owner = config.users.users.nextcloud.name;
          group = config.users.users.nextcloud.name;
        };
        nextcloudSecretFile = {
          owner = config.users.users.nextcloud.name;
          group = config.users.users.nextcloud.name;
        };
      })
      // optionalAttrs config.onlyofficeDocumentServer.enable (mkSecrets {
        onlyofficeDocumentServerKey = {
          # owner = config.users.users.onlyoffice.name;
          # group = config.users.users.onlyoffice.name;
        };
      });

    services = {
      nextcloud = mkIf config.nextcloud.enable {
        hostName = config.nextcloud.domain;
        enable = true;
        package = pkgs.nextcloud30;
        autoUpdateApps.enable = true;
        https = true;
        configureRedis = true;
        datadir = "/storage/nextcloud";
        database.createLocally = true;
        maxUploadSize = "10G";
        config = {
          adminpassFile = config.age.secrets.nextcloudAdmin.path;
          dbtype = "pgsql";
        };

        # apps
        extraApps =
          {
            inherit
              (config.services.nextcloud.package.packages.apps)
              contacts
              calendar
              tasks
              mail
              cospend
              end_to_end_encryption
              # forms
              
              groupfolders
              # maps
              
              music
              notes
              previewgenerator
              deck
              cookbook
              ;
          }
          // optionals config.authelia.enable {
            oidc_login = pkgs.fetchNextcloudApp {
              license = "agpl3Plus";
              url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.0/oidc_login.tar.gz";
              sha256 = "sha256-DrbaKENMz2QJfbDKCMrNGEZYpUEvtcsiqw9WnveaPZA=";
            };
          }
          // optionals config.onlyofficeDocumentServer.enable {
            inherit
              (config.services.nextcloud.package.packages.apps)
              onlyoffice
              ;
          };

        extraAppsEnable = true;
        # appstoreEnable = true; # DO NOT ENABLE, it will break the declarative config for apps

        settings =
          {
            mail_from_address = "nextcloud";
            mail_smtpmode = "smtp";
            mail_sendmailmode = "smtp";
            mail_domain = "onyx.ovh";
            mail_smtphost = "mtp.free.fr";
            mail_smtpauth = 1;
            mail_smtpport = 587;
            mail_smtpname = "eymeric.monitoring";
            maintenance_window_start = 1;
            default_phone_region = "FR";
            log_type = "file";
          }
          // optionals config.authelia.enable {
            user_oidc = {
              single_logout = false;
              auto_provision = true;
              soft_auto_provision = true;
            };

            allow_user_to_change_display_name = false;
            lost_password_link = "disabled";
            oidc_login_provider_url = "https://${config.authelia.domain}";
            oidc_login_client_id = "nextcloud";
            # oidc_login_client_secret = "insecure_secret"; # set in secret file
            oidc_login_auto_redirect = false;
            oidc_login_end_session_redirect = false;
            oidc_login_button_text = "Log in with Authelia";
            oidc_login_hide_password_form = false;
            oidc_login_use_id_token = true;
            oidc_login_attributes = {
              id = "preferred_username";
              name = "name";
              mail = "email";
              groups = "groups";
            };
            oidc_login_default_group = "oidc";
            oidc_login_use_external_storage = false;
            oidc_login_scope = "openid profile email groups";
            oidc_login_proxy_ldap = false;
            oidc_login_disable_registration = false; # different from doc, to enable auto creation of new users
            oidc_login_redir_fallback = false;
            oidc_login_tls_verify = false; # TODO set to true when using real certs
            oidc_create_groups = false;
            oidc_login_webdav_enabled = false;
            oidc_login_password_authentication = false;
            oidc_login_public_key_caching_time = 86400;
            oidc_login_min_time_between_jwks_requests = 10;
            oidc_login_well_known_caching_time = 86400;
            oidc_login_update_avatar = false;
            oidc_login_code_challenge_method = "S256";
          };
        # secret file currently only used to provide:
        # - oidc_login_client_secret for authelia
        # - mail_smtppassword for mail
        secretFile = mkIf config.authelia.enable config.age.secrets.nextcloudSecretFile.path;

        phpOptions = {
          "opcache.enable" = "1";
          "opcache.revalidate_freq" = "0";
          "opcache.memory_consumption" = "1024";
          "opcache.interned_strings_buffer" = "512";
        };
      };

      # onlyoffice = mkIf config.onlyofficeDocumentServer.enable {
      #   enable = true;
      #   hostname = config.onlyofficeDocumentServer.domain;
      #   jwtSecretFile = config.age.secrets.onlyofficeDocumentServerKey.path;
      #   port = config.onlyofficeDocumentServer.port;
      # };
    };
    virtualisation.oci-containers.containers.onlyoffice = mkIf config.onlyofficeDocumentServer.enable {
      image = "onlyoffice/documentserver:latest";
      ports = ["${toString config.onlyofficeDocumentServer.port}:80"];
      environmentFiles = [
        config.age.secrets.onlyofficeDocumentServerKey.path
      ];
    };
  };
}
