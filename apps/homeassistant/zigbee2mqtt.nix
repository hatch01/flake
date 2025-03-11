{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    zigbee2mqtt = {
      enable = mkEnableOption "enable zigbee2mqtt";
      port = mkOption {
        type = types.int;
        default = 8080;
        description = "The port on which zigbee2mqtt will listen";
      };
    };
  };

  config = mkIf config.zigbee2mqtt.enable {
    systemd.services.zigbee2mqtt.serviceConfig.Restart = "always";
    services.zigbee2mqtt = {
      enable = true;
      dataDir = "/storage/homeassistant/zigbee2mqtt";

      settings = {
        homeassistant = true;
        permit_join = false;
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://localhost";
        };
        serial = {
          port = "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240220202746-if00";
          adapter = "ember";
          baudrate = 230400;
        };
        frontend = {
          port = config.zigbee2mqtt.port;
        };
        advanced = {
          log_level = "warning";
        };
        external_converters = [
          "water.js"
        ];
        devices = {
          "0x00158d0005d263a7" = {
            friendly_name = "ZLinky";
            linky_mode = "standard";
            tarif = "Standard - Heure Pleine Heure Creuse";
            energy_phase = "auto";
            production = "false";
            kWh_precision = "3";
          };
          "0x70b3d52b600b8d61".friendly_name = "Frigo";
          "0xa4c13838417869a3".friendly_name = "temperature eymeric";
          "0x70b3d52b600bbd25".friendly_name = "Four";
          "0x70b3d52b600b87f6".friendly_name = "micro-onde; grille pain";
          "0xa4c1383010c51a37".friendly_name = "temperature Kevin";
          "0x70b3d52b600b8a69".friendly_name = "PC Kevin";
          "0xa4c1387c77f5cec7".friendly_name = "temperature Salon";
          "0xa4c138c7433ae2c1".friendly_name = "temperature Salle de Bain";
          "0xa4c1380f61a7c337".friendly_name = "temperature Cuisine";
          "0x70b3d52b600bc013".friendly_name = "Serveur";
          "0xa4c138ee4f964b0c".friendly_name = "Chauffe eau";
          "0x70b3d52b600a3c0f".friendly_name = "PC Eymeric";
          "0xa4c13825eae893f2".friendly_name = "Chauffage Couloir";
          "0xa4c1380d227318c3".friendly_name = "Chauffage Eymeric";
          "0xa4c138ccd59d1441".friendly_name = "Chauffage Kevin";
          "0xa4c1388a5d468383".friendly_name = "Chauffage Salon";
          "0xb40ecfd245230000".friendly_name = "Lumiere Eymeric";
          "0x70b3d52b600a3cef".friendly_name = "Plaque de cuisson";
          "0x70b3d52b600a4ffd".friendly_name = "Bouilloire";
          "0x70b3d52b600a4e24".friendly_name = "Lave linge";
          "0xb40ecfd1a9b30000".friendly_name = "Lumiere cuisine";
          "0x404ccafffe57e6ec".friendly_name = "Water Sensor";
        };
      };
    };

    services.mosquitto = {
      enable = true;
      dataDir = "/storage/homeassistant/mosquitto";
    };
  };
}
