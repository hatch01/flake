{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  imports = [
    ./home_assistant.nix
    ./zigbee2mqtt.nix
    ./influx.nix
    ./nodered.nix
    ./matter.nix
    ./openthread.nix
  ];

  options = {
    home_automation.enable = mkEnableOption "Home automation";
  };

  config = mkIf config.home_automation.enable {
    home_assistant.enable = true;
    zigbee2mqtt.enable = true;
    influxdb.enable = true;
    influxdb.grafana.enable = true;
    nodered.enable = true;
    openthread.enable = true;
    matter.enable = true;
    esp_home.enable = true;
  };
}
