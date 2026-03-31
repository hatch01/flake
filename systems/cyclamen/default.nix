{ base_domain_name, lib, ... }:

{
  imports = [ ];

  headscale.enable = true;
  beszel.hub.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;
  gatus.enable = true;
  ddclient.enable = true;
  ddclient.domains = [ "vps.${base_domain_name}" ];

  boot.loader.grub.enable = true;
  container.enable = lib.mkForce false;

  age.identityPaths = [ "/etc/age/key" ];

}
