{
  config,
  lib,
  stable,
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

  config = mkIf config.nginx.nichihachi.enable (
    if !stable then
      {
        # plain HTTP redirect
        services.nginx.virtualHosts."~^(nichihachi\\.net|.*\\.nichihachi\\.net)$" = {
          locations."/" = {
            return = "301 https://$host$request_uri";
          };
        };

        nginx.ports.httpsRedirect = 4444;
        services.tlsrouter = {
          enable = true;
          # Listen where the front-end (sslh) expects TLS, or on :443 if none.
          listen = ":${toString config.nginx.ports.https}";
          routes = {
            # nichihachi.net and all its subdomains -> external backend.
            # Attrset iteration is sorted, so this key (second char '(' = 0x28)
            # must sort BEFORE the catch-all below ('.' = 0x2E) to win.
            "/(^nichihachi\\.net|\\.nichihachi\\.net$)/" = {
              backend = "${config.nginx.nichihachi.backendIp}:443";
            };
            # Everything else -> local nginx, which listens on the redirect port.
            # Send HAProxy PROXY protocol so nginx can recover the real client IP
            # (tlsrouter is a plain proxy: without this nginx/Authelia only see
            # 127.0.0.1, breaking ip-based rules).
            "/.*/" = {
              backend = "127.0.0.1:${toString config.nginx.ports.httpsRedirect}";
              proxy = true;
            };
          };
        };
      }
    else
      { }
  );
}
