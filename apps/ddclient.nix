{
  lib,
  config,
  mkSecret,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
in
{
  options = {
    ddclient = {
      enable = mkEnableOption "enable ddclient";
      domains = mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Domains to update";
      };
    };
  };

  config = mkIf config.ddclient.enable {
    age.secrets = mkSecret "server/dyndns" { root = true; };

    systemd.services.ddclient.restartTriggers = [
      config.age.secrets."server/dyndns".file
    ];

    services.ddclient = {
      enable = true;
      protocol = "ovh";
      server = "www.ovh.com";
      username = "onyx.ovh-ddclient";
      passwordFile = config.age.secrets."server/dyndns".path;
      domains = config.ddclient.domains;
    };
  };
}
