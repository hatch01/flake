{
  config,
  lib,
  pkgs,
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

  shsPresenceZonesPackage = pkgs.buildNpmPackage rec {
    pname = "shs-z2m-presence-zones";
    version = "2.7.2";

    src = pkgs.fetchFromGitHub {
      owner = "notownblues";
      repo = "SHS-Z2M-Presence-Zones";
      rev = "feb203bf47ebb9df2eb14f4b78165c068bef93cc";
      sha256 = "0cpbkk7hs9k21v6rg3wzq497mli6ifvlw3bb3z0pl15zgw0p5rvm";
    };

    sourceRoot = "source/shs_z2m_presence_zones";

    npmDepsHash = "sha256-s8XfIiEC4CHNIDlHrHzKVtRaTxNo28F99p9LoRGAD+o=";

    npmBuildScript = "build";

    postInstall = ''
      # The server expects static files in www instead of dist
      mv $out/lib/node_modules/''${pname}/dist $out/lib/node_modules/''${pname}/www
    '';
  };
in
{
  options = {
    shs_presence_zones = {
      enable = mkEnableOption "SHS Z2M Presence Zones configurator";
      port = mkOption {
        type = types.int;
        default = 8099;
        description = "The port on which the web interface will listen";
      };
      domain = mkOption {
        type = types.str;
        default = "shs-presence.${base_domain_name}";
        description = "The domain name for the SHS Z2M Presence Zones configurator";
      };
      mqtt_host = mkOption {
        type = types.str;
        default = "localhost";
        description = "MQTT broker hostname or IP";
      };
      mqtt_ws_port = mkOption {
        type = types.int;
        default = 1884;
        description = "MQTT WebSocket port";
      };
    };
  };

  config = mkIf config.shs_presence_zones.enable {
    systemd.services.shs-presence-zones = {
      description = "SHS Z2M Presence Zones Configurator";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = toString config.shs_presence_zones.port;
        MQTT_HOST = config.shs_presence_zones.mqtt_host;
        MQTT_WS_PORT = toString config.shs_presence_zones.mqtt_ws_port;
        ROOM_CONFIGS_PATH = "/var/lib/shs-presence-zones/room_configs.json";
      };

      serviceConfig = {
        ExecStart = "${pkgs.nodejs}/bin/node ${shsPresenceZonesPackage}/lib/node_modules/shs-z2m-presence-zones/server.js";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "shs-presence-zones";
        WorkingDirectory = "${shsPresenceZonesPackage}/lib/node_modules/shs-z2m-presence-zones";
      };
    };
  };
}
