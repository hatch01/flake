{
  config,
  lib,
  pkgs,
  mkSecrets,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  imports = [];

  options = {
    matrix.mas.enable = mkEnableOption "enable matrix";
  };

  config = mkIf config.matrix.mas.enable {
    environment.systemPackages = [pkgs.matrix-authentication-service];
  };
}
