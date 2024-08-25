{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault mkIf;
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
