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
    heroic.enable = mkEnableOption "Enable Heroic";
  };

  config = with config; {
    steam = {
      enable = mkDefault gaming.enable;
      gamescopeSession.enable = mkDefault steam.enable;
      protonup.enable = mkDefault steam.enable;
    };
    remotePlay.enable = mkDefault gaming.enable;
    gamemode.enable = mkDefault gaming.enable;
    winetools.enable = mkDefault gaming.enable;
    minecraft.enable = mkDefault gaming.enable;
    heroic.enable = mkDefault gaming.enable;

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
      [mangohud dolphin-emu]
      ++ optionals config.steam.protonup.enable [protonup protontricks]
      ++ optionals config.minecraft.enable [prismlauncher]
      ++ optionals config.steam.enable [ludusavi] # a backup tool for Steam games
      ++ optionals config.remotePlay.enable [rustdesk parsec-bin]
      ++ optionals config.winetools.enable [bottles wine]
      ++ optionals config.heroic.enable [pkgs.heroic];
  };
}
