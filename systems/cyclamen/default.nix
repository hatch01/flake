{ mkSecrets, lib, ... }:

{
  imports = [ ];

  headscale.enable = true;
  beszel.hub.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;
  gatus.enable = true;

  boot.loader.grub.enable = true;
  container.enable = lib.mkForce false;

  age.identityPaths = [ "/etc/age/key" ];

}
