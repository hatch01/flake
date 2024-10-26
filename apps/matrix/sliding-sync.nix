{
  config,
  lib,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
in {
  options = {
    matrix.sliding-sync = {
      enable = mkEnableOption "enable matrix sliding sync";
      port = mkOption {
        type = lib.types.int;
        default = 8009;
      };
    };
  };
}
