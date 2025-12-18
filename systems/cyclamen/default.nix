{ mkSecrets, ... }:

{
  imports = [ ];

  boot.loader.grub.enable = true;

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
}
