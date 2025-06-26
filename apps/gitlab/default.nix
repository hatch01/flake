{
  config,
  lib,
  mkSecrets,
  base_domain_name,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    gitlab = {
      enable = mkEnableOption "enable Gitlab";
      domain = mkOption {
        type = types.str;
        default = "gitlab.${base_domain_name}";
        description = "The domain of the Gitlab instance";
      };
    };
  };

  imports = [
    ./runner.nix
  ];

  config = mkIf config.gitlab.enable {
    age.secrets = let
      cfg = {
        owner = "gitlab";
        group = "gitlab";
      };
    in
      mkSecrets
      {
        "gitlab/databasePasswordFile" = cfg;
        "gitlab/initialRootPasswordFile" = cfg;
        "gitlab/secretFile" = cfg;
        "gitlab/otpFile" = cfg;
        "gitlab/dbFile" = cfg;
        "gitlab/jwsFile" = cfg;
        "gitlab/openIdKey" = cfg;
      };

    users.users.gitlab.extraGroups = ["smtp"];

    services.gitlab = {
      enable = true;
      host = config.gitlab.domain;
      https = true;
      port = 443;
      statePath = "/storage/gitlab";
      databasePasswordFile = config.age.secrets."gitlab/databasePasswordFile".path;
      initialRootPasswordFile = config.age.secrets."gitlab/initialRootPasswordFile".path;
      secrets = {
        secretFile = config.age.secrets."gitlab/secretFile".path;
        otpFile = config.age.secrets."gitlab/otpFile".path;
        dbFile = config.age.secrets."gitlab/dbFile".path;
        jwsFile = config.age.secrets."gitlab/jwsFile".path;
      };

      smtp = {
        enable = true;
        address = "smtp.free.fr";
        port = 587;
        username = "eymeric.monitoring";
        passwordFile = config.age.secrets."server/smtpPassword".path;
      };

      # registry = {
      #   enable = true;
      # };

      extraConfig = {
        gitlab = {
          email_from = "gitlab@onyx.ovh";
          email_display_name = "GitLab";
          email_reply_to = "gitlab@onyx.ovh";
          signup_enabled = false;
        };

        # Authelia configuration
        omniauth = {
          enabled = true;
          auto_sign_in_with_provider = "openid_connect";
          allow_single_sign_on = ["openid_connect"];
          block_auto_created_users = false;
          providers = [
            {
              name = "openid_connect";
              label = "Authelia";
              icon = "https://www.authelia.com/images/branding/logo-cropped.png";
              args = {
                name = "openid_connect";
                strategy_class = "OmniAuth::Strategies::OpenIDConnect";
                issuer = "https://${config.authelia.domain}";
                discovery = true;
                scope = ["openid" "profile" "email" "groups"];
                client_auth_method = "basic";
                response_type = "code";
                response_mode = "query";
                uid_field = "preferred_username";
                send_scope_to_token_endpoint = true;
                pkce = true;
                client_options = {
                  identifier = "gitlab";
                  secret = {_secret = "${config.age.secrets."gitlab/openIdKey".path}";};
                  redirect_uri = "https://${config.gitlab.domain}/users/auth/openid_connect/callback";
                };
              };
            }
          ];
        };
      };
    };
  };
}
