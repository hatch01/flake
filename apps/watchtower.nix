{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    watchtower.enable = mkEnableOption "Watchtower";
  };

  config = mkIf config.watchtower.enable {
    virtualisation.oci-containers.containers."watchtower" = {
      autoStart = true;
      image = "nickfedor/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };
}
