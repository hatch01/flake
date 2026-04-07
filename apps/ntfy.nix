{
  lib,
  config,
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
    ntfy = {
      enable = mkEnableOption "enable ntfy";
      domain = mkOption {
        type = types.str;
        default = "ntfy.${base_domain_name}";
        description = "The domain of the ntfy instance";
      };
      port = mkOption {
        type = types.int;
        default = 2586;
        description = "The port on which ntfy listens";
      };
    };
  };

  config = mkIf config.ntfy.enable {
    age.secrets = mkSecret "ntfy_auth_users_env" { };

    systemd.services.ntfy-sh.after = [ "network.target" "postgresql.service" ];
    services.ntfy-sh = {
      enable = true;
      environmentFile = config.age.secrets."ntfy_auth_users_env".path;
      settings = {
        listen-http = "127.0.0.1:${toString config.ntfy.port}";
        base-url = "https://${config.ntfy.domain}";
        behind-proxy = true;

        #CREATE ROLE "ntfy-sh" LOGIN;
        #CREATE DATABASE ntfy OWNER "ntfy-sh";
        #GRANT ALL PRIVILEGES ON DATABASE ntfy TO "ntfy-sh";
        database-url = "postgres:///ntfy?host=/run/postgresql";
        auth-file = "";
        cache-file = "";
        web-push-file = "";

        auth-default-access = "deny-all";
        auth-access = [
          "*:up*:write-only"
          "eymeric:*:rw"
        ];
        enable-login = true;
        require-login = true;
      };
    };
  };
}
