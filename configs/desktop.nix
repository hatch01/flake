{
  inputs,
  pkgs,
  ...
}: {
  home-manager.sharedModules = with inputs; [plasma-manager.homeManagerModules.plasma-manager];

  imports = [
    ../apps/plasma/plasma.nix
    ../apps/zsh.nix
    ../apps/keepassxc.nix
    ../apps/neovim.nix
    ../apps/cloud-storage
    ../apps/thunderbird.nix
    ../apps/social
    #../apps/espanso.nix
    ../apps/konsole.nix
    ../apps/homebank.nix
    ../apps/multimedia.nix
    ../apps/kde-connect.nix
    ../apps/dev
    ../apps/tools.nix
    ../apps/office
  ];

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
      gnome.gnome-disk-utility
      libsForQt5.kpmcore
      glxinfo
      appimage-run
      firefox
      ungoogled-chromium
      tor-browser
      floorp
      sqlitebrowser
      kdePackages.yakuake
      wl-clipboard
    ];
  };
}
