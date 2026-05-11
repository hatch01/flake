{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options = {
    nginx.nichihachi = {
      enable = mkEnableOption "SNI-based routing for nichihachi.net";
      backendIp = mkOption {
        type = types.nullOr types.str;
        description = "IP address to redirect nichihachi.net traffic to";
      };
    };
  };

  config = mkIf config.nginx.nichihachi.enable {
    # plain HTTP redirect
    services.nginx.virtualHosts."~^(nichihachi\.net|.*\.nichihachi\.net)$" = {
      locations."/" = {
        return = "301 https://$host$request_uri";
      };
    };

    # HTTPS/TLS routing
    nginx.ports.httpsRedirect = 4444;
    services.nginx = {
      streamConfig = ''
        map $ssl_server_name $backend {
          ~^(nichihachi\.net|.*\.nichihachi\.net)$ "${config.nginx.nichihachi.backendIp}:443";
          default "127.0.0.1:${toString config.nginx.ports.httpsRedirect}";
        }

        server {
          listen ${
            if config.nginx.ports.https != 443 then "127.0.0.1" else "0.0.0.0"
          }:${toString config.nginx.ports.https};
          listen ${
            if config.nginx.ports.https != 443 then "[::1]" else "[::]"
          }:${toString config.nginx.ports.https};

          # Enable SNI inspection without terminating TLS
          ssl_preread on;

          proxy_pass $backend;
        }
      '';
    };
  };
}
