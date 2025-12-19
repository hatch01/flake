{
  lib,
  config,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    optionals
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
    services.headscale = {
      enable = true;
      address = "::1";
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
      };
    };
  };
}
