{
  lib,
  config,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    ddclient = {
      enable = mkEnableOption "enable ddclient";
    };
  };

  config = mkIf config.ddclient.enable {
    age.secrets = mkSecret "dyndns" {};

    services.ddclient = {
      enable = true;
      protocol = "dyndns2";
      server = "www.ovh.com";
      username = "onyx.ovh-ddclient";
      passwordFile = config.age.secrets.dyndns.path;
      usev4 = "web";
      ssl = false;
      domains = [
        config.adguard.domain
        config.gitlab.domain
        config.authelia.domain
        config.nextcloud.domain
        config.matrix.domain
        config.homepage.domain
        config.netdata.domain
        config.nixCache.domain
        config.homeassistant.domain
        config.onlyofficeDocumentServer.domain
      ];
    };
  };
}
