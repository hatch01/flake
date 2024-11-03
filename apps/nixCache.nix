{
  config,
  lib,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    nixCache = {
      enable = mkEnableOption "enable nixCache";
      domain = mkOption {
        type = types.str;
        default = "cache.${config.networking.domain}";
        description = "The domain of the nixCache instance";
      };
      port = mkOption {
        type = types.int;
        default = 5000;
      };
    };
  };

  config = mkIf config.nixCache.enable {
    users = {
      users.nix-serve = {
        isSystemUser = true;
        group = "nix-serve";
      };
      groups.nix-serve = {};
    };

    age.secrets = mkSecret "cache-priv-key.pem" {
      owner = "nix-serve";
    };
    services.nix-serve = {
      enable = true;
      port = config.nixCache.port;
      secretKeyFile = config.age.secrets."cache-priv-key.pem".path;
    };
  };
}
