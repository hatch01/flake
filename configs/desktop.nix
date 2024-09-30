{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./wifi.nix
  ];

  # apps enabling
  plasma.enable = true;

  # dev
  dev.enable = true;
  dev.androidtools.enable = true;
  jetbrains.enable = true;
  vscode.enable = true;

  # office
  libreoffice.enable = true;
  onlyofficeDesktopEditor.enable = true;
  ghostwriter.enable = true;
  cloud-storage.enable = true;

  # keepass
  keepassxc.enable = true;
  keepassxc.autostart = true;

  social.enable = true;
  #vesktop.enable = false; default to the same value as social.enable

  espanso.enable = false;
  homebank.enable = true;
  container.distrobox.enable = true;
  vm.enable = true;
  kdeconnect.enable = true;
  konsole.enable = true;

  multimedia.enable = true;
  multimedia.editing.enable = true;
  neovim.enable = true;
  thunderbird.enable = true;
  ollama.enable = true;

  gaming.enable = true;
  # remotePlay.enable = false # enabled by default if gaming.enable is true
  # steam = {
  #   enable = false # enabled by default if gaming.enable is true
  #   gamescopeSession.enable = false # enabled by default if steam.enable is true
  #   protonup.enable = false # enabled by default if steam.enable is true
  # };
  # gamemode.enable = false # enabled by default if gaming.enable is true
  # minecraft.enable = false # enabled by default if gaming.enable is true
  # winetools.enable = false # enabled by default if gaming.enable is true
  # heroic.enable = false # enabled by default if gaming.enable is true

  home-manager.sharedModules = with inputs; [plasma-manager.homeManagerModules.plasma-manager];

  services.flatpak = {
    enable = true;
    update.auto = {
      enable = true;
      onCalendar = "weekly"; # Default value
    };
    packages = [
    ];
  };

  programs.nix-ld.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["Hack" "JetBrainsMono"];})
  ];

  environment = {
    systemPackages = with pkgs; [
      (catppuccin-kde.override {flavour = ["mocha" "latte"];})
      catppuccin-cursors.mochaDark
      partition-manager
      gnome-disk-utility
      libsForQt5.kpmcore
      glxinfo
      appimage-run
      firefox
      ungoogled-chromium
      tor-browser
      floorp
      sqlitebrowser
      kdePackages.yakuake
      kdePackages.ktorrent
      wl-clipboard
    ];
  };
}
