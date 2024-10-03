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
          useACMEHost = config.hostName;
          enableACME = config.nginx.acme.enable;
          extraConfig = "proxy_cache cache;\n";
        };
        baseUrl = "https://${config.matrix.hostName}";
        clientConfig = {
          "m.homeserver".base_url = baseUrl;
          "org.matrix.msc3575.proxy" = {
            url = baseUrl;
            issuer = "https://${config.authelia.hostName}/";
            account = "https://${config.authelia.hostName}/account/";
          };
        };
        serverConfig."m.server" = "${config.matrix.hostName}:443";
        mkWellKnown = data: ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON data}';
        '';
        autheliaProxy = {
          proxyPass = "${
            if config.authelia.enable
            then "http://[::1]:${toString config.authelia.port}"
            else "https://${toString config.authelia.hostName}"
          }/api/authz/auth-request";
          recommendedProxySettings = false;
          extraConfig = builtins.readFile ./auth-location.conf;
        };
      in
        {}
        // {
          "${config.hostName}" = mkIf config.homepage.enable {
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

              "= /.well-known/matrix/server".extraConfig = mkIf config.matrix.enable (mkWellKnown serverConfig);
              "= /.well-known/matrix/client".extraConfig = mkIf config.matrix.enable (mkWellKnown clientConfig);
            };
          };
        }
        // {
          ${config.netdata.hostName} = mkIf config.netdata.enable {
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
          ${config.adguard.hostName} = mkIf config.adguard.enable {
            inherit (cfg) forceSSL enableACME;
            locations = {
              "/" = {
                proxyPass = "https://[::1]:${toString config.adguard.port}";
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
          # TODO create a simplified method to define those
          ${config.nextcloud.hostName} = mkIf config.nextcloud.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
          };
        }
        // {
          ${config.onlyofficeDocumentServer.hostName} = mkIf config.onlyofficeDocumentServer.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
          };
        }
        // {
          ${config.gitlab.hostName} = mkIf config.gitlab.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
          };
        }
        // {
          ${config.matrix.hostName} = let
            clientConfig."m.homeserver".base_url = "https://${config.matrix.hostName}";
          in
            mkIf config.matrix.enable {
              inherit (cfg) forceSSL extraConfig enableACME;
              serverAliases = [config.matrix.hostName];
              root = mkIf config.matrix.enableElement (pkgs.element-web.override {
                conf = {
                  default_server_config = clientConfig; # see `clientConfig` from the snippet above.
                };
              });
              locations = {
                "/".extraConfig = mkIf (! config.matrix.enableElement) ''
                  return 404;
                '';
                # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
                # *must not* be used here.
                "/_matrix".proxyPass = "http://[::1]:${toString config.matrix.port}";
                # Forward requests for e.g. SSO and password-resets.
                "/_synapse/client".proxyPass = "http://[::1]:${toString config.matrix.port}";

                "~ ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync)" = mkIf config.matrix.sliding-sync.enable {
                  proxyPass = "http://[::1]:${toString config.matrix.sliding-sync.port}";
                };

                "~ ^(\/_matrix|\/_synapse\/client)" = mkIf config.matrix.sliding-sync.enable {
                  proxyPass = "http://[::1]:${toString config.matrix.port}";
                };
              };
            };
        }
        // {
          ${config.nixCache.hostName} = mkIf config.nixCache.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations."/".proxyPass = "http://[::1]:${toString config.nixCache.port}";
          };
        }
        // {
          ${config.homeassistant.hostName} = mkIf config.homeassistant.enable {
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
          ${config.authelia.hostName} = mkIf config.authelia.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            locations = let
              authUrl = "http://[::1]:${toString config.authelia.port}";
            in {
              "/".proxyPass = authUrl;
              "/api/verify".proxyPass = authUrl;
              "/api/authz".proxyPass = authUrl;
            };
          };
        };
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
