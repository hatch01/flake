{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    optionals
    mkEnableOption
    mkDefault
    mkIf
    ;
in
{
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

    programs.alvr = {
      enable = true;
      openFirewall = true;
    };

    services.monado = {
      enable = true;
      defaultRuntime = true; # Register as default OpenXR runtime
    };
    systemd.user.services.monado.environment = {
      STEAMVR_LH_ENABLE = "1";
      XRT_COMPOSITOR_COMPUTE = "1";
    };

    environment.sessionVariables = mkIf steam.protonup.enable {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    environment.systemPackages =
      with pkgs;
      with config;
      [ ]
      ++ optionals gaming.enable [
        mangohud
        dolphin-emu
      ]
      ++ optionals steam.protonup.enable [
        protonup-ng
        protontricks
      ]
      ++ optionals minecraft.enable [ prismlauncher ]
      ++ optionals steam.enable [ ludusavi ] # a backup tool for Steam games
      ++ optionals remotePlay.enable [ parsec-bin ]
      ++ optionals winetools.enable [
        bottles
        wine
      ]
      ++ optionals heroic.enable [ pkgs.heroic ];
  };
}
