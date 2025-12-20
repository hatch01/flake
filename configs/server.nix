{ mkSecret, ... }:
{
  imports = [ ];

  age.secrets = mkSecret "server/cockpit_private_key" {
    mode = "600";
    root = true;
    path = "/root/.ssh/id_rsa";
  };
}
