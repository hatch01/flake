{
  lib,
  config,
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
  options = {
    openthread = {
      enable = mkEnableOption "enable openthread";
      restPort = mkOption {
        type = types.int;
        default = 8089;
        description = "The port on which openthread will listen";
      };
      webPort = mkOption {
        type = types.int;
        default = 8091;
        description = "The port on which openthread web interface will listen";
      };
      domain = mkOption {
        type = types.str;
        default = "thread.${base_domain_name}";
      };
    };
  };

  config = mkIf config.openthread.enable {
    services.openthread-border-router = {
      backboneInterface = "eno1";
      enable = true;
      radio = {
        device = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_5449f26b5b53ef11b6e222e0174bec31-if00-port0";
        baudRate = 460800;
      };
      rest = {
        listenAddress = "0.0.0.0";
        listenPort = config.openthread.restPort;
      };
      web = {
        listenPort = config.openthread.webPort;
      };
    };
  };
}
