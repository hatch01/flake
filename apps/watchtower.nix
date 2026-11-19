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
    watchtower.enable = mkEnableOption "Podman container auto-update timer";
  };

  config = mkIf config.watchtower.enable {
    systemd.timers."podman-auto-update".wantedBy = [ "timers.target" ];
  };
}
