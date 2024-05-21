{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) optionals mkEnableOption mkDefault mkIf;
in {
  options = {
    gaming.enable = mkEnableOption "Enable Gaming";
    remotePlay.enable = mkEnableOption "Enable Steam Remote Play";
    steam = {
      enable = mkEnableOption "Enable Steam";
      gamescopeSession.enable = mkEnableOption "Enable GameScope session";
      protonup.enable = mkEnableOption "Enable ProtonUp";
    };
    gamemode.enable = mkEnableOption "Enable GameMode";
    minecraft.enable = mkEnableOption "Enable Minecraft";
    winetools.enable = mkEnableOption "Enable Wine Tools";
  };

  config = with config; {
    steam = {
      enable = mkDefault gaming.enable;
      gamescopeSession.enable = mkDefault steam.enable;
      protonup.enable = mkDefault steam.enable;
    };
    remotePlay.enable = mkDefault gaming.enable;
    gamemode.enable = mkDefault gaming.enable;

    programs = {
      gamemode.enable = gamemode.enable;
      steam = {
        enable = steam.enable;
        remotePlay.openFirewall = remotePlay.enable; # Open ports in the firewall for Steam Remote Play
        gamescopeSession.enable = steam.gamescopeSession.enable;
      };
    };

    environment.sessionVariables = mkIf steam.protonup.enable {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    environment.systemPackages = with pkgs;
    with config;
      [
        mangohud
      ]
      ++ optionals steam.protonup.enable [protonup protontricks]
      ++ optionals minecraft.enable [prismlauncher]
      ++ optionals steam.enable [ludusavi] # a backup tool for Steam games
      ++ optionals remotePlay.enable [rustdesk parsec-bin]
      ++ optionals winetools.enable [bottles wine];
  };
}
