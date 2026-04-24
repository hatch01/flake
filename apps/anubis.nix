{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  resolvePath = path: lib.foldl' (acc: part: acc.${part}) config (lib.splitString "." path);
in
{
  options = {
    anubis = {
      enable = mkEnableOption "enable Anubis proxy";
      services = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of services to protect with Anubis (e.g., [\"forgejo\" \"nextcloud\"])";
      };
    };
  };

  imports = [ ];

  config = mkIf config.anubis.enable {
    services.anubis =
      let
        mkInstance =
          serviceName:
          let
            svc = resolvePath serviceName;
          in
          {
            settings = {
              TARGET = "http://127.0.0.1:${toString svc.port}";
              BIND = "/run/anubis/anubis-${serviceName}/anubis.sock";
              METRICS_BIND = "/run/anubis/anubis-${serviceName}/anubis-metrics.sock";
            };
          };

        instances = lib.listToAttrs (
          map (serviceName: lib.nameValuePair serviceName (mkInstance serviceName)) config.anubis.services
        );
      in
      {
        defaultOptions.policy.settings = {
          openGraph = {
            enabled = true;
            considerHost = false;
            ttl = "4h";
          };
        };

        inherit instances;
      };

    # required due to unix socket permissions
    users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
  };
}
