{pkgs, ...}: {
  programs = {
    gamemode.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      package = pkgs.steam.override {
        extraLibraries = pkgs: [pkgs.openssl pkgs.nghttp2 pkgs.libidn2 pkgs.rtmpdump pkgs.libpsl pkgs.curl pkgs.krb5 pkgs.keyutils];
      };
      gamescopeSession.enable = true;
    };
  };

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  environment.systemPackages = with pkgs; [
    # gaming
    bottles
    mangohud
    protonup
    prismlauncher
    ludusavi
    rustdesk
    protontricks
    wine
    parsec-bin
  ];
}
