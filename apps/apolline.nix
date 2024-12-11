{
  lib,
  config,
  inputs,
  pkgs,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf;
in {
  options = {
    apolline.enable = mkEnableOption "Enable apolline";
    apolline.port = mkOption {
      type = lib.types.int;
      default = 3003;
      description = "The port of the apolline";
    };
    apolline.domain = mkOption {
      type = lib.types.str;
      default = "apolline.${config.networking.domain}";
      description = "The domain of the apolline";
    };
  };

  config = mkIf config.apolline.enable {
    age.secrets = mkSecret "apolline" {};

    users = {
      users.apolline = {
        group = "apolline";
        isSystemUser = true;
      };
      groups.apolline = {};
    };

    systemd.services.apolline = {
      enable = true;
      description = "apolline";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "on-failure";
        EnvironmentFile = config.age.secrets.apolline.path;

        ExecStart = "${inputs.apolline.packages.${pkgs.system}.default}/bin/apolline";
        User = "apolline";
        Group = "apolline";
        WorkingDirectory = "/storage/apolline";
      };
      environment = {
        PORT = "${toString config.apolline.port}";
        HOST = "::";
      };
    };
  };
}
