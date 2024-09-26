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

  config = mkIf config.matrix.sliding-sync.enable {
    age.secrets = mkSecret "matrix_sliding_sync" {};
    services.matrix-sliding-sync = {
      enable = true;
      createDatabase = true;
      environmentFile = config.age.secrets.matrix_sliding_sync.path;
      settings = {
        SYNCV3_SERVER = "http://[::1]:${toString config.matrix.port}";
        SYNCV3_DB = "postgresql:///matrix-sliding-sync?host=/run/postgresql";
        SYNCV3_BINDADDR = "0.0.0.0:${toString config.matrix.sliding-sync.port}";
      };
    };
  };
}
