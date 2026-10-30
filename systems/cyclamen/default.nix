{
  base_domain_name,
  lib,
  config,
  ...
}:

{
  imports = [ ];

  headscale.enable = true;
  headplane.enable = true;
  beszel.hub.enable = true;
  nginx.enable = true;
  nginx.acme.enable = true;
  gatus.enable = true;
  ddclient.enable = true;
  ddclient.domains = [ "vps.${base_domain_name}" ];
  fail2ban.enable = true;
  lasuite-meet.enable = true;

  cockpit.enable = true;
  cockpit.domain = "cyclamen:9090";
  # Cockpit is only reachable through the tailnet
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.cockpit.port
  ];

  boot.loader.grub.enable = true;
  container.enable = lib.mkForce false;

  age.identityPaths = [ "/etc/age/key" ];

}
