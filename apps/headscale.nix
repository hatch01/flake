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
    ;
in
{
  options = {
    headscale.enable = mkEnableOption "Enable service";
    headscale.port = mkOption {
      type = lib.types.int;
      default = 8092;
      description = "The port of the headscale";
    };
    headscale.domain = mkOption {
      type = lib.types.str;
      default = "headscale.${base_domain_name}";
      description = "The domain of the cockpit";
    };
  };

  config = mkIf config.headscale.enable {
    age.secrets = mkSecret "headscale_oidc" {
      owner = "headscale";
      group = "headscale";
    };

    services.headscale = {
      enable = true;
      port = config.headscale.port;
      settings = {
        server_url = "https://${config.headscale.domain}";

        dns = {
          base_domain = "onyx.lan";
          magic_dns = true;
          search_domains = [ config.headscale.domain ];
          nameservers.global = [
            "9.9.9.9"
          ];
        };

        ip_prefixes = [
          "100.64.0.0/10"
          "fd7a:115c:a1e0::/48"
        ];

        oidc = {
          issuer = "https://${config.authelia.domain}";
          client_id = "headscale";
          client_secret_path = config.age.secrets.headscale_oidc.path;
          scope = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          pkce = {
            enabled = true;
            code_challenge_method = "S256";
          };
        };
      };
    };
  };
}
