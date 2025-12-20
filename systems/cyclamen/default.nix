{ mkSecrets, lib, ... }:

{
  imports = [ ];

  headscale.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;

  boot.loader.grub.enable = true;
  container.enable = lib.mkForce false;

  age = {
    identityPaths = [ "/etc/age/key" ];

    secrets = mkSecrets {
      "server/smtpPassword" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
      "server/smtpPasswordEnv" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
    };
  };
  users = {
    groups.smtp = { };
  };
}
