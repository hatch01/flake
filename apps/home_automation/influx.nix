{
  config,
  lib,
  mkSecret,
  base_domain_name,
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
    influxdb = {
      enable = mkEnableOption "TimescaleDB";
      port = mkOption {
        type = types.int;
        default = 8086;
      };

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
    };
  };

  config = mkIf config.influxdb.enable {
    age.secrets = mkSecret "authelia/gitlabSecret" {
      owner = "grafana";
    };

    services.grafana = mkIf config.influxdb.grafana.enable {
      enable = true;
      dataDir = "/persistent/grafana";
      settings = {
        server = {
          # Listening Address
          http_addr = "::1";
          # and Port
          http_port = config.influxdb.grafana.port;
          # Grafana needs to know on which domain and URL it's running
          domain = config.influxdb.grafana.domain;
          root_url = "https://${config.influxdb.grafana.domain}";
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

    virtualisation.oci-containers = {
      containers.influxdb = {
        volumes = [ "/storage/influxdb/:/var/lib/influxdb2" ];
        image = "influxdb:latest";
        ports = [ "127.0.0.1:${toString config.influxdb.port}:8086" ];
      };
    };

    postgres.initialScripts = [
      ''
        CREATE USER homeassistant WITH PASSWORD 'homeassistant';
        CREATE DATABASE homeassistant_db WITH OWNER homeassistant ENCODING 'utf8' TEMPLATE template0;
      ''
    ];
  };
}
