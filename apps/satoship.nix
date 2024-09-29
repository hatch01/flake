{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    satoship.enable = mkEnableOption "Enable satohip";
  };

  config = mkIf config.satoship.enable {
    environment.systemPackages = with pkgs; [
      pcsclite
    ];
  };
}
