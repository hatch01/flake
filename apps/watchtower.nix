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
    hmr.services.podman.enable = true;
    hmr.services.podman.autoUpdate.enable = true;
    # virtualisation.oci-containers.containers."watchtower" = {
    #   autoStart = true;
    #   image = "docker.io/nickfedor/watchtower";
    #   volumes = [
    #     "/var/run/docker.sock:/var/run/docker.sock"
    #   ];
    # };
  };
}
