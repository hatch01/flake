{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
in {
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
      additionalModules = with pkgs.nginxModules; [modsecurity];
      proxyCachePath = {
        "" = {
          enable = true;
          keysZoneName = "cache";
        };
      };

      virtualHosts = let
        cfg = {
          forceSSL = config.nginx.acme.enable;
          useACMEHost = config.networking.domain;
          enableACME = config.nginx.acme.enable;
          extraConfig = "proxy_cache cache;\n";
        };
        clientConfig =
          if config.matrix.enable
          then {
            "m.homeserver".base_url = "https://${config.matrix.domain}";
            "org.matrix.msc2965.authentication" = {
              "issuer" = "https://${config.networking.domain}/";
              "account" = "https://${config.matrix.mas.domain}/account";
            };
          }
          else {};
        mkWellKnown = data: ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON data}';
        '';
        autheliaProxy = {
          proxyPass = "${
            if config.authelia.enable
            then "http://[::1]:${toString config.authelia.port}"
            else "https://${toString config.authelia.domain}"
          }/api/authz/auth-request";
          recommendedProxySettings = false;
          extraConfig = builtins.readFile ./auth-location.conf;
        };
      in
        {}
        // {
          "${config.networking.domain}" = mkIf config.homepage.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = mkIf config.homepage.enable {
                proxyPass = "http://[::1]:${toString config.homepage.port}";
                extraConfig = lib.strings.concatStringsSep "\n" [
                  (builtins.readFile ./auth-authrequest.conf)
                ];
              };

              # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
              "/internal/authelia/authz" = autheliaProxy;

              "= /.well-known/matrix/server".extraConfig = mkIf config.matrix.enable (mkWellKnown {"m.server" = "${config.matrix.domain}:443";});
              "= /.well-known/matrix/client".extraConfig = mkIf config.matrix.enable (mkWellKnown clientConfig);
              "= /.well-known/openid-configuration".proxyPass = "http://[::1]:${toString config.matrix.mas.port}";
            };
          };
        }
        // {
          ${config.netdata.domain} = mkIf config.netdata.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = {
                proxyPass = "http://[::1]:${toString config.netdata.port}";
                extraConfig = lib.strings.concatStringsSep "\n" [
                  (builtins.readFile ./auth-authrequest.conf)
                ];
              };
              # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
              "/internal/authelia/authz" = autheliaProxy;
            };
          };
        }
        // {
          ${config.cockpit.domain} = mkIf config.cockpit.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = {
                proxyPass = "http://[::1]:${toString config.cockpit.port}";
                extraConfig = ''
                  # Required for web sockets to work
                  proxy_http_version 1.1;
                  proxy_buffering off;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";

                  # Pass ETag header from Cockpit to clients.
                  # See: https://github.com/cockpit-project/cockpit/issues/5239
                  gzip off;'';
              };
            };
          };
        }
        // {
          ${config.adguard.domain} = mkIf config.adguard.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = {
                proxyPass = "https://[::1]:${toString config.adguard.port}";
                extraConfig = lib.strings.concatStringsSep "\n" [
                  (builtins.readFile ./auth-authrequest.conf)
                ];
              };

              # Homepage need to access control/stats without authentication
              "/control/stats".proxyPass = "https://[::1]:${toString config.adguard.port}";
              # dns-query does not need any authentication
              "/dns-query".proxyPass = "https://[::1]:${toString config.adguard.port}";

              # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
              "/internal/authelia/authz" = autheliaProxy;
            };
          };
        }
        // {
          # TODO create a simplified method to define those
          ${config.nextcloud.domain} = mkIf config.nextcloud.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
          };
        }
        // {
          ${config.onlyofficeDocumentServer.domain} = mkIf config.onlyofficeDocumentServer.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations."/".proxyPass = "http://[::1]:${toString config.onlyofficeDocumentServer.port}";
          };
        }
        // {
          ${config.gitlab.domain} = mkIf config.gitlab.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
          };
        }
        // {
          ${config.matrix.domain} = mkIf config.matrix.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            root = mkIf config.matrix.enableElement (pkgs.element-web.override {
              conf = {
                default_server_config = clientConfig; # see `clientConfig` from the snippet above.
              };
            });
            locations = {
              "/".extraConfig = mkIf (! config.matrix.enableElement) ''
                return 404;
              '';

              # Forward to the auth service
              "~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
                priority = 100;
                proxyPass = "http://[::1]:${toString config.matrix.mas.port}";
              };

              "~ ^(/_matrix|/_synapse/client)".proxyPass = "http://[::1]:${toString config.matrix.port}";
            };
          };
        }
        // {
          ${config.matrix.mas.domain} = mkIf config.matrix.mas.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations = {
              "/".proxyPass = "http://[::1]:${toString config.matrix.mas.port}";
              "/assets/".root = "${pkgs.matrix-authentication-service}/share/matrix-authentication-service/";
            };
          };
        }
        // {
          ${config.nixCache.domain} = mkIf config.nixCache.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations."/".proxyPass = "http://127.0.0.1:${toString config.nixCache.port}";
          };
        }
        // {
          ${config.homeassistant.domain} = mkIf config.homeassistant.enable {
            inherit (cfg) forceSSL enableACME;
            extraConfig = ''
              proxy_buffering off;
            '';
            locations."/" = {
              proxyPass = "http://[::1]:${toString config.homeassistant.port}";
              proxyWebsockets = true;
            };
          };
        }
        // {
          ${config.authelia.domain} = mkIf config.authelia.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations = let
              authUrl = "http://[::1]:${toString config.authelia.port}";
            in {
              "/".proxyPass = authUrl;
              "/api/verify".proxyPass = authUrl;
              "/api/authz".proxyPass = authUrl;
            };
          };
        }
        // {
          ${config.librespeed.domain} = mkIf config.librespeed.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = {
                proxyPass = "http://[::1]:${toString config.librespeed.port}";
                extraConfig = lib.strings.concatStringsSep "\n" [
                  (builtins.readFile ./auth-authrequest.conf)
                ];
              };
              # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
              "/internal/authelia/authz" = autheliaProxy;
            };
          };
        };
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
