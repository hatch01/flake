{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  imports = [
    ./zigbee2mqtt.nix
    ./influx.nix
  ];

  options = {
    homeassistant = {
      enable = mkEnableOption "Home Assistant";
      domain = mkOption {
        type = types.str;
        default = "home.${config.networking.domain}";
      };
      port = mkOption {
        type = types.int;
        default = 8123;
      };
    };
  };

  config = mkIf config.homeassistant.enable {
    zigbee2mqtt.enable = true;
    influxdb.enable = true;
    influxdb.grafana.enable = true;
    virtualisation.oci-containers.containers.homeassistant = {
      volumes = ["/storage/homeassistant/:/config"];
      environment.TZ = "Europe/Paris";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        "--network=host"
        "--add-host=host.docker.internal:host-gateway"
      ];
    };

    postgres.initialScripts = [
      ''
        CREATE USER homeassistant WITH PASSWORD 'homeassistant';
        CREATE DATABASE homeassistant_db WITH OWNER homeassistant ENCODING 'utf8' TEMPLATE template0;
      ''
    ];
  };
}
