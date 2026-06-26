{
  lib,
  config,
  base_domain_name,
  mkSecrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    ;
in
{
  options = {
    headplane.enable = mkEnableOption "Enable Headplane";
    headplane.port = mkOption {
      type = lib.types.int;
      default = 8094;
      description = "The port of the Headplane UI";
    };
    headplane.domain = mkOption {
      type = lib.types.str;
      default = config.headscale.domain;
      description = "The domain of the Headplane UI";
    };
  };

  config = mkIf config.headplane.enable {
    age.secrets = mkSecrets {
      "headplane_cookie" = {
        owner = "headscale";
        group = "headscale";
      };
      "headscale_api_key" = {
        owner = "headscale";
        group = "headscale";
      };
      "headplane_oidc" = {
        owner = "headscale";
        group = "headscale";
      };
      "headplane_pre_authkey" = {
        owner = "headscale";
        group = "headscale";
      };
    };

    services.headplane = {
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = config.headplane.port;
          base_url = "https://${config.headplane.domain}";
          cookie_secret_path = config.age.secrets.headplane_cookie.path;
          cookie_secure = true;
        };

        headscale = {
          url = "http://127.0.0.1:${toString config.headscale.port}";
          public_url = "https://${config.headscale.domain}";
          config_path = "/etc/headscale/config.yaml";
        };

        integration = {
          proc.enabled = true;
          agent = {
            enabled = true;
            pre_authkey_path = config.age.secrets.headplane_pre_authkey.path;
          };
        };

        oidc = {
          enabled = true;
          issuer = "https://${config.authelia.domain}";
          client_id = "headplane";
          client_secret_path = config.age.secrets.headplane_oidc.path;
          headscale_api_key_path = config.age.secrets.headscale_api_key.path;
          scope = "openid profile email groups";
          use_pkce = true;
        };
      };
    };
  };
}
