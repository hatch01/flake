{
  lib,
  config,
  base_domain_name,
  mkSecret,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    lasuite-meet = {
      enable = mkEnableOption "Enable La Suite Meet";
      domain = mkOption {
        type = types.str;
        default = "meet.${base_domain_name}";
        description = "The domain of La Suite Meet";
      };
    };
  };

  config = mkIf config.lasuite-meet.enable {
    # Securely load the OIDC secrets via Agenix
    age.secrets = mkSecret "lasuite-meet" { };

    services.lasuite-meet = {
      enable = true;
      inherit (config.lasuite-meet) domain;
      environmentFile = config.age.secrets.lasuite-meet.path;

      enableNginx = true;
      postgresql.createLocally = true;
      redis.createLocally = true;

      # We disable the local LiveKit instance since we'll reuse the existing one
      livekit.enable = false;

      settings = {
        OIDC_OP_JWKS_ENDPOINT = "https://${config.authelia.domain}/jwks.json";
        OIDC_OP_AUTHORIZATION_ENDPOINT = "https://${config.authelia.domain}/api/oidc/authorization";
        OIDC_OP_TOKEN_ENDPOINT = "https://${config.authelia.domain}/api/oidc/token";
        OIDC_OP_USER_ENDPOINT = "https://${config.authelia.domain}/api/oidc/userinfo";
        OIDC_RP_CLIENT_ID = "lasuite-meet";
        OIDC_RP_SIGN_ALGO = "RS256";
        OIDC_RP_SCOPES = "openid email profile";
        OIDC_USERINFO_FULLNAME_FIELDS = "name";
        OIDC_USERINFO_SHORTNAME_FIELD = "preferred_username";

        LOGIN_REDIRECT_URL = "https://${config.lasuite-meet.domain}";
        LOGIN_REDIRECT_URL_FAILURE = "https://${config.lasuite-meet.domain}";
        LOGOUT_REDIRECT_URL = "https://${config.lasuite-meet.domain}";

        # Reuse existing LiveKit server configured in Element Call
        LIVEKIT_API_URL = "wss://${config.matrix.domain}/livekit/sfu";
      };
    };

    # Inject ACME / SSL settings for the Nginx virtual host configured by La Suite Meet
    services.nginx.virtualHosts."${config.lasuite-meet.domain}" = {
      forceSSL = config.nginx.acme.enable;
      enableACME = config.nginx.acme.enable;
    };
  };
}
