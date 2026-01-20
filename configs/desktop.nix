{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./wifi.nix
  ];

  # apps enabling
  plasma.enable = mkDefault true;

  # dev
  dev.enable = mkDefault true;
  dev.androidtools.enable = mkDefault true;
  jetbrains.enable = mkDefault true;
  vscode.enable = mkDefault true;

  # office
  libreoffice.enable = mkDefault true;
  onlyofficeDesktopEditor.enable = mkDefault true;
  ghostwriter.enable = mkDefault true;
  cloud-storage.enable = mkDefault true;

  # keepass
  keepassxc.enable = mkDefault true;
  keepassxc.autostart = mkDefault true;
  bitwarden.enable = mkDefault true;

  social.enable = mkDefault true;

  espanso.enable = false;
  homebank.enable = mkDefault true;
  container.distrobox.enable = mkDefault true;
  vm.enable = mkDefault true;
  kdeconnect.enable = mkDefault true;
  konsole.enable = mkDefault true;

  multimedia.enable = mkDefault true;
  multimedia.editing.enable = mkDefault true;
  multimedia.audio.enable = mkDefault true;
  thunderbird.enable = mkDefault true;
  ollama.enable = mkDefault true;

  gaming.enable = mkDefault true;
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

  basic-tools.enable = mkDefault true;
  bitcoin.client.enable = mkDefault true;
  office.enable = mkDefault true;
  yubikey.enable = mkDefault true;

  home-manager.sharedModules = with inputs; [ plasma-manager.homeModules.plasma-manager ];

  programs.nix-ld.enable = true;

  fonts.packages = with pkgs.nerd-fonts; [
    hack
    jetbrains-mono
  ];

  # programs.ssh = {
  #   extraConfig = ''
  #     Host *
  #       IdentityFile /home/${username}/.ssh/yubikey
  #   '';
  # };

  programs.firefox.enable = true;

  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  environment = {
    systemPackages = with pkgs; [
      (catppuccin-kde.override {
        flavour = [
          "mocha"
          "latte"
        ];
      })
      catppuccin-cursors.mochaDark
      kdePackages.partitionmanager
      gnome-disk-utility
      kdePackages.kpmcore
      mesa-demos
      appimage-run
      ungoogled-chromium
      tor-browser
      sqlitebrowser
      antares
      kdePackages.yakuake
      kdePackages.ktorrent
      wl-clipboard
      pwvucontrol
      gnupg
    ];
  };
}
