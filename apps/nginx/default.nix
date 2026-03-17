{
  config,
  lib,
  pkgs,
  base_domain_name,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  mkVhostLogs =
    name:
    let
      safeName = builtins.replaceStrings [ "." ] [ "_" ] name;
    in
    ''
      access_log /var/log/nginx/${safeName}_access.log combined buffer=64k flush=5m;
      error_log /var/log/nginx/${safeName}_error.log;
    '';

  # Resolve a dotted path like "beszel.hub" into config.beszel.hub
  resolvePath = path: lib.foldl' (acc: part: acc.${part}) config (lib.splitString "." path);

  authRequestConf = builtins.readFile ./auth-authrequest.conf;

  autheliaProxy = {
    proxyPass = "${
      if config.authelia.enable then
        "http://[::1]:${toString config.authelia.port}"
      else
        "https://${toString config.authelia.domain}"
    }/api/authz/auth-request";
    recommendedProxySettings = false;
    extraConfig = builtins.readFile ./auth-location.conf;
  };

  # mkVhost "serviceName" { ... }
  #
  # Auto-resolves config.<serviceName>.{enable,domain,port}
  # Generates: ACME, forceSSL, per-vhost logs, proxyPass to port
  #
  # Options:
  #   cache              - bool, add proxy_cache (default: false)
  #   authelia           - bool, add authelia auth-request on "/" and authz location (default: false)
  #   extraConfig        - string, additional nginx server-level config (default: "")
  #   locations          - attrset, deep-merged with the default locations (default: {})
  #   noDefaultLocations - bool, omit default "/" location entirely (default: false)
  #   Any other key is passed through to the virtualHost (e.g. root)
  mkVhost =
    serviceName:
    {
      cache ? false,
      authelia ? false,
      extraConfig ? "",
      locations ? { },
      noDefaultLocations ? false,
      ...
    }@overrides:
    let
      svc = resolvePath serviceName;
      domain = svc.domain;
      enable = svc.enable;
      port = svc.port;

      # Server-level extraConfig
      serverExtraParts =
        lib.optional cache "proxy_cache cache;" ++ lib.optional (extraConfig != "") extraConfig;
      fullExtraConfig = lib.concatStringsSep "\n" (serverExtraParts ++ [ (mkVhostLogs domain) ]);

      # User-provided "/" location overrides
      userRootLoc = locations."/" or { };

      # Concatenate extraConfig parts for "/" location: authelia first, then user's
      rootLocExtraConfig = lib.concatStringsSep "\n" (
        lib.optional authelia authRequestConf
        ++ lib.optional (userRootLoc ? extraConfig) userRootLoc.extraConfig
      );

      # Build the "/" location: defaults + user overrides + merged extraConfig
      rootLocation = {
        proxyPass = "http://127.0.0.1:${toString port}";
      }
      // userRootLoc
      // lib.optionalAttrs (rootLocExtraConfig != "") { extraConfig = rootLocExtraConfig; };

      # All other user locations (excluding "/")
      otherUserLocations = builtins.removeAttrs locations [ "/" ];

      # Authelia authz location
      autheliaLocations = lib.optionalAttrs authelia {
        "/internal/authelia/authz" = autheliaProxy;
      };

      defaultLocations = {
        "/" = rootLocation;
      }
      // autheliaLocations
      // otherUserLocations;

      effectiveLocations =
        if noDefaultLocations then autheliaLocations // locations else defaultLocations;

      passthroughOverrides = builtins.removeAttrs overrides [
        "cache"
        "authelia"
        "extraConfig"
        "locations"
        "noDefaultLocations"
      ];
    in
    {
      ${domain} = mkIf enable (
        {
          forceSSL = config.nginx.acme.enable;
          enableACME = config.nginx.acme.enable;
          extraConfig = fullExtraConfig;
        }
        // lib.optionalAttrs (effectiveLocations != { }) {
          locations = effectiveLocations;
        }
        // passthroughOverrides
      );
    };

  clientConfig =
    lib.optionalAttrs config.matrix.enable {
      "m.homeserver".base_url = "https://${config.matrix.domain}";
      "org.matrix.msc2965.authentication" = {
        "issuer" = "https://${base_domain_name}";
        "account" = "https://${config.matrix.mas.domain}/account";
      };
      oidc_static_clients = {
        "https://${base_domain_name}" = {
          client_id = "0000000000000000000SYNAPSE";
        };
      };
    }
    // lib.optionalAttrs (config.matrix.enable && config.matrix.elementCall.enable) {
      "org.matrix.msc4143.rtc_foci" = [
        {
          type = "livekit";
          livekit_service_url = "https://${config.matrix.domain}/livekit/jwt";
        }
      ];
    };

  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  options = {
    nginx.enable = mkEnableOption "Nginx";
    nginx.acme.enable = mkEnableOption "Enable ACME terms";
  };

  config = mkIf config.nginx.enable {
    security.acme = mkIf config.nginx.acme.enable {
      acceptTerms = true;
      defaults = {
        email = "eymeric.monitoring@free.fr";
      };
    };

    # when we have dns
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      commonHttpConfig = ''
        access_log off;
      '';
      proxyCachePath = {
        "" = {
          enable = true;
          keysZoneName = "cache";
        };
      };

      virtualHosts = lib.mkMerge [

        (mkVhost "homepage" {
          authelia = true;
          locations = {
            "= /.well-known/matrix/server".extraConfig = mkIf config.matrix.enable (mkWellKnown {
              "m.server" = "${config.matrix.domain}:443";
            });
            "= /.well-known/matrix/client".extraConfig = mkIf config.matrix.enable (mkWellKnown clientConfig);
            "= /.well-known/openid-configuration".proxyPass = "http://[::1]:${toString config.matrix.mas.port}";
          };
        })

        (mkVhost "beszel.hub" { })

        (mkVhost "gatus" { })

        (mkVhost "cockpit" {
          locations."/" = {
            recommendedProxySettings = false;
            extraConfig = ''
              # Required for web sockets to work
              proxy_http_version 1.1;
              proxy_buffering off;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              gzip off;
            '';
          };
        })

        (mkVhost "adguard" {
          authelia = true;
          locations = {
            "/".proxyPass = "https://127.0.0.1:${toString config.adguard.port}";
            # Homepage needs to access control/stats without authentication
            "/control/stats".proxyPass = "https://127.0.0.1:${toString config.adguard.port}";
            # dns-query does not need any authentication
            "/dns-query".proxyPass = "https://127.0.0.1:${toString config.adguard.port}";
          };
        })

        (mkVhost "nextcloud" { noDefaultLocations = true; })

        (mkVhost "onlyofficeDocumentServer" {
          cache = true;
          noDefaultLocations = true;
        })

        (mkVhost "forgejo" {
          cache = true;
          extraConfig = ''
            client_max_body_size 512M;
          '';
        })

        (mkVhost "matrix" {
          cache = true;
          noDefaultLocations = true;
          root = mkIf config.matrix.enableElement (
            pkgs.element-web.override {
              conf = {
                default_server_config = clientConfig;
              };
            }
          );
          locations = {
            "/".extraConfig = mkIf (!config.matrix.enableElement) ''
              return 404;
            '';

            "~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
              priority = 100;
              proxyPass = "http://[::1]:${toString config.matrix.mas.port}";
            };

            "~ ^(/_matrix|/_synapse/client)" = {
              proxyPass = "http://[::1]:${toString config.matrix.port}";
              extraConfig = ''
                client_max_body_size 10G;
              '';
            };
            "/health".proxyPass = "http://[::1]:${toString config.matrix.port}/health";

            "^~ /livekit/jwt/" = mkIf config.matrix.elementCall.enable {
              proxyPass = "http://localhost:${toString config.matrix.elementCall.jwtServicePort}/";
            };

            "^~ /livekit/sfu/" = mkIf config.matrix.elementCall.enable {
              proxyPass = "http://localhost:${toString config.matrix.elementCall.livekitPort}/";
              proxyWebsockets = true;
            };
          };
        })

        (mkVhost "matrix.mas" {
          cache = true;
          locations = {
            "/assets/".root = "${pkgs.matrix-authentication-service}/share/matrix-authentication-service/";
            "/health".proxyPass = "http://localhost:${toString config.matrix.mas.port2}";
          };
        })

        (mkVhost "nixCache" { })

        (mkVhost "home_assistant" {
          extraConfig = "proxy_buffering off;";
          locations."/".proxyWebsockets = true;
        })

        (mkVhost "authelia" {
          cache = true;
          locations = {
            "/api/verify".proxyPass = "http://[::1]:${toString config.authelia.port}";
            "/api/authz".proxyPass = "http://[::1]:${toString config.authelia.port}";
          };
        })

        (mkVhost "librespeed" { authelia = true; })

        (mkVhost "apolline" { authelia = true; })

        (mkVhost "portfolio" { })

        (mkVhost "incus" {
          locations."/".extraConfig = ''
            # Required for web sockets to work
            proxy_buffering off;
            client_max_body_size 0;
            send_timeout  3600s;
            proxy_http_version 1.1;
            proxy_connect_timeout  3600s;
            proxy_read_timeout  3600s;
            proxy_send_timeout  3600s;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        })

        (mkVhost "nodered" {
          cache = true;
          authelia = true;
          locations = {
            "/".extraConfig = ''
              proxy_buffering off;
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
            "/health".proxyPass = "http://127.0.0.1:${toString config.nodered.port}/health";
          };
        })

        (mkVhost "zigbee2mqtt" {
          authelia = true;
          locations."/".proxyWebsockets = true;
        })

        (mkVhost "esp_home" {
          authelia = true;
          locations."/".proxyWebsockets = true;
        })

        (mkVhost "wakapi" { })

        (mkVhost "vaultwarden" { cache = true; })

        (mkVhost "headscale" {
          cache = true;
          locations = {
            "= /" = {
              root = "/";
              tryFiles = "${./headscale.html} =404";
              extraConfig = ''
                default_type text/html;
              '';
            };
            "/" = {
              proxyWebsockets = true;
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
              '';
            };
          };
        })
      ];
    };
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
