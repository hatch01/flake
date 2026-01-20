{
  config,
  lib,
  mkSecret,
  base_domain_name,
  pkgs,
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
  imports = [
    ./zigbee2mqtt.nix
  ];

  options = {
      grafana = {
        enable = mkEnableOption "Grafana";
        port = mkOption {
          type = types.int;
          default = 3002;
        };
        domain = mkOption {
          type = types.str;
          default = "grafana.${base_domain_name}";
        };
      };

    victoriametrics = {
      enable = mkEnableOption "VictoriaMetrics";
      port = mkOption {
        type = types.int;
        default = 8428;
      };
    };
  };

  config = mkIf config.victoriametrics.enable {
    age.secrets = mkSecret "authelia/gitlabSecret" {
      owner = "grafana";
    };

    services.grafana = mkIf config.grafana.enable {
      enable = true;
      dataDir = "/persistent/grafana";
      declarativePlugins = with pkgs.grafanaPlugins; [ victoriametrics-metrics-datasource ];
      settings = {
        server = {
          http_addr = "::1";
          http_port = config.grafana.port;
          domain = config.grafana.domain;
          root_url = "https://${config.grafana.domain}";
          serve_from_sub_path = true;
        };
        "auth.generic_oauth" = {
          enabled = true;
          auto_login = true;
          name = "Authelia";
          icon = "signin";
          client_id = "grafana";
          client_secret = "$__file{${config.age.secrets."authelia/gitlabSecret".path}}";
          scopes = "openid profile email groups";
          empty_scopes = false;
          auth_url = "https://${config.authelia.domain}/api/oidc/authorization";
          token_url = "https://${config.authelia.domain}/api/oidc/token";
          api_url = "https://${config.authelia.domain}/api/oidc/userinfo";
          login_attribute_path = "preferred_username";
          groups_attribute_path = "groups";
          name_attribute_path = "name";
          use_pkce = true;
          role_attribute_path = "contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
        };
      };
    };

    services.victoriametrics = mkIf config.victoriametrics.enable {
      enable = true;
      retentionPeriod = "5y";
      listenAddress = "127.0.0.1:${toString config.victoriametrics.port}";
    };

    # Bind mount /storage/victoriametrics vers /var/lib/victoriametrics
    fileSystems."/var/lib/victoriametrics" = mkIf config.victoriametrics.enable {
      device = "/storage/victoriametrics";
      options = [ "bind" ];
    };

    postgres.initialScripts = [
      ''
        CREATE USER homeassistant WITH PASSWORD 'homeassistant';
        CREATE DATABASE homeassistant_db WITH OWNER homeassistant ENCODING 'utf8' TEMPLATE template0;
      ''
    ];
  };
}
