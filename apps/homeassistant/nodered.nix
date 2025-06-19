{
  config,
  lib,
  mkSecret,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    nodered = {
      enable = mkEnableOption "Home Assistant";
      domain = mkOption {
        type = types.str;
        default = "nodered.${config.networking.domain}";
      };
      port = mkOption {
        type = types.int;
        default = 1880;
      };
    };
  };

  config = mkIf config.nodered.enable {
    age.secrets = mkSecret "node_red" {
        owner = config.services.node-red.user;
        group = config.services.node-red.group;
    };
    services.node-red = {
      enable = true;
      withNpmAndGcc = true;
      port = config.nodered.port;
      userDir = "/storage/node-red";
      configFile = "/storage/node-red/settings.js";
    };
    systemd.services.node-red.serviceConfig = {
      ExecStartPre = pkgs.writeShellScript "node-red-pre-start" ''
        cp ${config.services.node-red.package}/lib/node_modules/node-red/packages/node_modules/node-red/settings.js /storage/node-red/settings.js
        chmod 644 /storage/node-red/settings.js
        sed -i "s|//credentialSecret: \"a-secret-key\",|$(cat ${config.age.secrets.node_red.path})|" /storage/node-red/settings.js
      '';
    };
  };
}
