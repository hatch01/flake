{
  lib,
  config,
  inputs,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options = {
    portfolio.enable = mkEnableOption "Enable portfolio";
    portfolio.port = mkOption {
      type = lib.types.int;
      default = 3005;
      description = "The port of the portfolio";
    };
    portfolio.domain = mkOption {
      type = lib.types.str;
      default = "clement-reniers.fr";
      description = "The domain of the portfolio";
    };
  };

  config = mkIf config.portfolio.enable {
    users = {
      users.portfolio = {
        group = "portfolio";
        isSystemUser = true;
      };
      groups.portfolio = { };
    };

    systemd.services.portfolio = {
      enable = true;
      description = "portfolio";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "on-failure";
        ExecStart = "${inputs.portfolio.packages.${system}.default}/bin/portfolio";
        User = "portfolio";
        Group = "portfolio";
      };
      environment = {
        PORT = "${toString config.portfolio.port}";
        HOST = "::";
      };
    };
  };
}
