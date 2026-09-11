{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkDefault;
in
{
  options = {
    atop.enable = mkEnableOption "Enable atop, a tool for monitoring system resources";
    atop.netatop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the netatop kernel module";
    };
  };

  config = mkIf config.atop.enable {
    programs.atop.enable = true;
    programs.atop.netatop.enable = mkDefault config.atop.netatop.enable;
  };
}
