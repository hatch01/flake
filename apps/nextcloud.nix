{
  config,
  mkSecret,
  mkSecrets,
  lib,
  pkgs,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
    optionals
    mkDefault
    mkForce
    ;
in
{
  options = {
    nextcloud = {
      enable = mkEnableOption "Nextcloud";
      domain = mkOption {
        type = types.str;
        default = "nextcloud.${base_domain_name}";
      };
      port = mkOption {
        type = types.int;
        default = 443;
      };
      app_api = {
        enable = mkEnableOption "Nextcloud app_api (DSP)";
        dspPort = mkOption {
          type = types.int;
          default = 2375;
          description = "Port for Docker Socket Proxy";
        };
      };
    };
    onlyofficeDocumentServer = {
      enable = mkEnableOption "OnlyOffice document server";
      domain = mkOption {
        type = types.str;
        default = "onlyoffice.${base_domain_name}";
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
      // optionalAttrs config.onlyofficeDocumentServer.enable (mkSecret "onlyofficeDocumentServerKey" { })
      // optionalAttrs config.nextcloud.app_api.enable (mkSecret "nextcloudDspPassword" { });

    nextcloud.app_api.enable = mkDefault config.nextcloud.enable;
    services = {
      redis.package = pkgs.valkey;
      nextcloud = mkIf config.nextcloud.enable {
        hostName = config.nextcloud.domain;
        enable = true;
        package = pkgs.nextcloud32;
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
        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps)
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

          # assistant = pkgs.fetchNextcloudApp {
          #   url = "https://github.com/nextcloud/assistant/archive/refs/tags/v2.9.0.tar.gz";
          #   hash = "sha256-OHImheA26C+gA1IcXNrWM2V2ejEKe1riYXmw3FDEGsg=";
          #   license = "agpl3Only";
          # };
          # translate2 = pkgs.fetchNextcloudApp {
          #   url = "https://github.com/nextcloud/translate2/archive/refs/tags/v2.2.0.tar.gz";
          #   hash = "sha256-m7S95+pjCwh2NPO66kFo/N6KUP6KooyYscVPQ8SWVYY=";
          #   license = "agpl3Plus";
          # };
          # stt_whisper2 = pkgs.fetchNextcloudApp {
          #   url = "https://github.com/nextcloud/stt_whisper2/archive/refs/tags/v2.3.0.tar.gz";
          #   hash = "sha256-BNM8IKY7BZHzGCfObg3tkPrXiLe2bU7lTt2851WS2Ws=";
          #   license = "agpl3Plus";
          # };
          # llm2 = pkgs.fetchNextcloudApp {
          #   url = "https://github.com/nextcloud/llm2/archive/refs/tags/v2.4.2.tar.gz";
          #   hash = "sha256-aLFh76wfFTfAReC+RqZm8P1EnAKmyoVYZqw4zcnbCNA=";
          #   license = "agpl3Plus";
          # };
          app_api = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud/app_api/archive/refs/tags/v32.0.1.tar.gz";
            hash = "sha256-NL/Jeej8S3heJ2WuAIEbDmdo8IhOfYeGqpL7kucCVZU=";
            license = "agpl3Only";
          };
        }
        // optionals config.authelia.enable {
          oidc_login = pkgs.fetchNextcloudApp {
            license = "agpl3Plus";
            url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.2/oidc_login.tar.gz";
            sha256 = "sha256-RLYquOE83xquzv+s38bahOixQ+y4UI6OxP9HfO26faI=";
          };
        }
        // optionals config.onlyofficeDocumentServer.enable {
          inherit (config.services.nextcloud.package.packages.apps)
            onlyoffice
            ;
        };

        extraAppsEnable = true;
        appstoreEnable = true; # DO NOT ENABLE, it will break the declarative config for apps

        settings = {
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
          oidc_login_auto_redirect = true;
          oidc_login_end_session_redirect = false;
          oidc_login_button_text = "Log in with Authelia";
          oidc_login_hide_password_form = false;
          oidc_login_use_id_token = false;
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
          oidc_login_tls_verify = true;
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
    virtualisation.oci-containers.containers = {
      onlyoffice = mkIf config.onlyofficeDocumentServer.enable {
        image = "onlyoffice/documentserver:latest";
        ports = [ "${toString config.onlyofficeDocumentServer.port}:80" ];
        environmentFiles = [
          config.age.secrets.onlyofficeDocumentServerKey.path
        ];
      };

      app_api-dsp = mkIf config.nextcloud.app_api.enable {
        image = "ghcr.io/nextcloud/nextcloud-appapi-dsp:release";
        autoStart = true;
        hostname = "nextcloud-appapi-dsp";
        privileged = true;
        environment = { };
        environmentFiles = [
          config.age.secrets.nextcloudDspPassword.path
        ];
        ports = [
          "127.0.0.1:${toString config.nextcloud.app_api.dspPort}:${toString config.nextcloud.app_api.dspPort}"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
      };
    };

    services.phpfpm.pools.nextcloud.user = "nextcloud";
    services.phpfpm.pools.nextcloud.phpEnv.PATH =
      mkForce "/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:${
        lib.makeBinPath [ config.services.phpfpm.pools.nextcloud.phpPackage ]
      }";
  };
}
