{
  config,
  lib,
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
  options = {
    esp_home = {
      enable = mkEnableOption "esp home";
      domain = mkOption {
        type = types.str;
        default = "esp.${base_domain_name}";
      };
      port = mkOption {
        type = types.int;
        default = 6052;
      };
    };
  };

  config = mkIf config.esp_home.enable {
    virtualisation.oci-containers.containers.esphome = {
      volumes = [ "/persistent/esphome:/config" ];
      environment.TZ = "Europe/Paris";
      image = "ghcr.io/esphome/esphome";
      extraOptions = [
        "--network=host"
      ];
    };
    # environment.persistence."/persistent" = {
    #   directories = [
    #     {
    #       directory = "/var/lib/esphome";
    #       user = "esphome";
    #       group = "esphome";
    #     }
    #   ];
    # };
    # services.esphome = {
    #   enable = true;
    #   port = config.esp_home.port;
    #   allowedDevices = [ ]; # Force no access to serial devices
    # };
  };
}
