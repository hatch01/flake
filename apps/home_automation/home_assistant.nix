{
  config,
  lib,
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
    home_assistant = {
      enable = mkEnableOption "Home Assistant";
      domain = mkOption {
        type = types.str;
        default = "home.${base_domain_name}";
      };
      port = mkOption {
        type = types.int;
        default = 8123;
      };
    };
  };

  config = mkIf config.home_assistant.enable {
    virtualisation.oci-containers.containers.home_assistant = {
      volumes = [ "/storage/home_assistant/:/config" ];
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
