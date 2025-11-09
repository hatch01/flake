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
      volumes = [
        "/storage/home_assistant/:/config"
        "/run/postgresql:/run/postgresql:ro"
      ];
      environment.TZ = "Europe/Paris";
      image = "ghcr.io/home-assistant/home-assistant:stable";
      user = "2001:2001";
      networks = [ "host" ];
    };

    users.groups.homeassistant.gid = 2001;
    users.users.homeassistant = {
      uid = 2001;
      group = "homeassistant";
      isSystemUser = true;
    };

    postgres.initialScripts = [
      ''
        CREATE USER homeassistant;
        CREATE DATABASE homeassistant_db WITH OWNER homeassistant ENCODING 'utf8' TEMPLATE template0;
      ''
    ];
  };
}
