{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    matter = {
      enable = mkEnableOption "enable matter";
      port = mkOption {
        type = types.int;
        default = 5580;
        description = "The port on which matter will listen";
      };
    };
  };

  config = mkIf config.matter.enable {
    virtualisation.oci-containers.containers.matter-server = {
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      volumes = [
        "/persistent/matter-server:/data"
        "/run/dbus:/run/dbus:ro"
      ];
      extraOptions = [
        "--security-opt=apparmor=unconfined"
      ];
      networks = [ "host" ];
      cmd = [
        "--storage-path"
        "/data"
        "--port"
        (toString config.matter.port)
      ];
    };
  };
}
