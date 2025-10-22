{
  lib,
  config,
  base_domain_name,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options = {
    vaultwarden.enable = mkEnableOption "Enable vaultWarden";
    vaultwarden.port = mkOption {
      type = lib.types.int;
      default = 8222;
      description = "The port of the vaultWarden";
    };
    vaultwarden.domain = mkOption {
      type = lib.types.str;
      default = "vaultwarden.${base_domain_name}";
      description = "The domain for VaultWarden";
    };
  };

  config = mkIf config.vaultwarden.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://${config.vaultwarden.domain}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "::1";
        ROCKET_PORT = config.vaultwarden.port;
        SMTP_HOST = "smtp.free.fr";
        SMTP_USERNAME = "eymeric.monitoring";
        SMTP_PORT = 587;
        SMTP_FROM = "vaultwarden@onyx.ovh";
        SMTP_FROM_NAME = "VaultWarden";
      };
      backupDir = "/storage/vaultwarden_backup";
      # dbBackend = "postgresql";
      environmentFile = config.age.secrets."server/smtpPasswordEnv".path;
    };

    environment.persistence."/persistent" = {
      directories = [ "/var/lib/bitwarden_rs" ];
    };
  };
}
