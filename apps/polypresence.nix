{
  lib,
  config,
  inputs,
  pkgs,
  base_domain_name,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf getExe;
in {
  options = {
    polypresence.enable = mkEnableOption "Enable polypresence";
    polypresence.backPort = mkOption {
      type = lib.types.int;
      default = 3006;
      description = "The port for the polypresence backend";
    };

    polypresence.frontPort = mkOption {
      type = lib.types.int;
      default = 8088;
      description = "The port for the polypresence frontend";
    };
    polypresence.domain = mkOption {
      type = lib.types.str;
      default = "polypresence.${base_domain_name}";
      description = "The domain of the polypresence";
    };

    polypresence.frontPath = mkOption {
      type = lib.types.path;
      default = inputs.polypresence.packages.${pkgs.system}.front.override {
        domain = config.polypresence.domain;
      };
      description = "Path to the polypresence frontend";
    };
  };

  config = mkIf config.polypresence.enable {
    users = {
      users.polypresence = {
        group = "polypresence";
        isSystemUser = true;
      };
      groups.polypresence = {};
    };

    systemd.services.polypresence-back = {
      enable = true;
      description = "polypresence backend";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "on-failure";
        ExecStart = "${getExe inputs.polypresence.packages.${pkgs.system}.back}";
        User = "polypresence";
        Group = "polypresence";
        EnvironmentFile = config.age.secrets."server/smtpPasswordEnv".path;
      };
      environment = {
        ASPNETCORE_URLS = "http://127.0.0.1:${toString config.polypresence.backPort}\;http://[::1]:${toString config.polypresence.backPort}";
        ASPNETCORE_ENVIRONMENT = "Production";
        DOTNET_USE_POLLING_FILE_WATCHER = toString 1;
        SMTP_USERNAME = "eymeric.monitoring";
        SMTP_FROM_EMAIL = "polypresence@onyx.fr";
        SMTP_HOST = "smtp.free.fr";
        SMTP_PORT = toString 587;
        FRONTEND_URL = "https://${config.polypresence.domain}";
        STORAGE_PATH = "/storage/polypresence/";
        MAIL_SENT_HOUR = toString 20;
        MAIL_SENT_MINUTE = toString 0;
        MAIL_SENT_SECOND = toString 0;
        EDT_IMPORT_TIME_HOUR = toString 12;
        EDT_IMPORT_TIME_MINUTE = toString 16;
        EDT_IMPORT_TIME_SECOND = toString 0;
      };
    };
  };
}
