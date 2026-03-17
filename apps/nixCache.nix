{
  config,
  lib,
  mkSecret,
  base_domain_name,
  stable,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  harmoniaConfig = {
    enable = true;
    signKeyPaths = [ config.age.secrets."cache-priv-key.pem".path ];
    settings = {
      bind = "[::]:${toString config.nixCache.port}";
    };
  };
in
{
  options = {
    nixCache = {
      enable = mkEnableOption "enable nixCache";
      domain = mkOption {
        type = types.str;
        default = "cache.${base_domain_name}";
        description = "The domain of the nixCache instance";
      };
      port = mkOption {
        type = types.int;
        default = 5001;
      };
    };
  };

  config = mkIf config.nixCache.enable {
    age.secrets = mkSecret "cache-priv-key.pem" {
      owner = "harmonia";
    };
    services.harmonia = if stable then harmoniaConfig else { cache = harmoniaConfig; };
  };
}
