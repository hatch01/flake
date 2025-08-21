{
  config,
  lib,
  base_domain_name,
  mkSecret,
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
    wakapi = {
      enable = mkEnableOption "enable wakapi";
      domain = mkOption {
        type = types.str;
        default = "wakapi.${base_domain_name}";
        description = "The domain of the wakapi instance";
      };
      port = mkOption {
        type = types.int;
        default = 3007;
        description = "The port to listen on";
      };
    };
  };

  config = mkIf config.wakapi.enable {
    age.secrets = mkSecret "server/wakapi_salt" {
      group = "wakapi";
      owner = "wakapi";
      root = true;
    };

    services = {
      wakapi = {
        enable = true;
        settings = {
          server = {
            public_url = "https://${config.wakapi.domain}:${toString config.wakapi.port}";
            port = config.wakapi.port;
          };

          stateDir = "/storage/wakapi";

          db = {
            host = "localhost";
            port = 5432;
            user = "wakapi";
            password = "wakapi";
            name = "wakapi";
            dialect = "postgres";
          };
          security = {
            allow_signup = false;
          };
          mail = {
            enabled = false;
          };
        };
        passwordSaltFile = config.age.secrets."server/wakapi_salt".path;
      };
    };
    postgres.initialScripts = [
      ''
        CREATE USER "wakapi" WITH LOGIN PASSWORD 'wakapi';
        CREATE DATABASE "wakapi" WITH OWNER "wakapi";
      ''
    ];
  };
}
