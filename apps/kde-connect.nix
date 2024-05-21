{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    kdeconnect.enable = mkEnableOption "kdeconnect-kde";
  };

  config = mkIf config.kdeconnect.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.kdeconnect-kde
    ];

    networking.firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };
  };
}
