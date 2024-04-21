{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "eymeric";
  home.homeDirectory = "/home/eymeric";
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.
  imports = [
    apps/zsh.nix
    apps/plasma/plasma.nix
    apps/neovim.nix
    apps/onedrive/onedrive.nix
    apps/ghostwriter.nix
    apps/thunderbird.nix
    apps/vscode.nix
    apps/vesktop/vesktop.nix
    #apps/espanso.nix
    apps/konsole.nix
    apps/homebank.nix
    inputs.flatpaks.homeManagerModules.nix-flatpak
    inputs.plasma-manager.homeManagerModules.plasma-manager
    inputs.nur.nixosModules.nur
  ];

  programs.git = {
    enable = true;
    userName = "eymeric";
    userEmail = "eymericdechelette@gmail.com";
    signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs";
    signing.signByDefault = true;
    extraConfig = {
      pull.rebase = true;
      safe.directory = "/etc/nixos";
      merge.conflictstyle = "diff3";
      merge.tool = "vimdiff";
      gpg.format = "ssh";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      diff.colorMoved = "default";
      rebase.autoStash = true;
      merge.autoStash = true;
      status.showStash = true;
      push.autoSetupRemote = true;
    };
    aliases = {
      tree = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # see note on other shells below
    nix-direnv.enable = true;
  };

  services.flatpak = {
    update.auto = {
      enable = true;
      onCalendar = "weekly"; # Default value
    };
    packages = [
      "it.fabiodistasio.AntaresSQL"
    ];
  };

  home.packages = with pkgs; [
    (nerdfonts.override {fonts = ["Hack" "JetBrainsMono"];})
    (catppuccin-kde.override {flavour = ["mocha" "latte"];})
    catppuccin-cursors.mochaDark
    hyfetch

    # archives
    zip
    unzip
    # networking tools
    nmap # A utility for network discovery and security auditing
    # misc
    file
    which
    tree
    gnupg
    bat
    thefuck
    trash-cli
    # productivity
    glow # markdown previewer in terminal
    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
    firefox
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.phpstorm
    #android-studio
    jetbrains-toolbox
    keepassxc
    sqlitebrowser
    ungoogled-chromium
    kate
    gimp
    geogebra6
    nodePackages.ungit
    lazygit
    inkscape-with-extensions
    insomnia
    kdePackages.kcolorchooser
    kdePackages.kdenlive
    glaxnimate
    krename
    kdePackages.ktorrent
    localsend
    kdePackages.kdeconnect-kde
    minder
    nasc
    obs-studio
    onlyoffice-bin
    libreoffice-qt
    hunspell
    hunspellDicts.fr-any
    steam
    signal-desktop
    syncthing
    syncthingtray
    nextcloud-client
    textpieces
    tor-browser
    kdePackages.yakuake
    zap
    superTuxKart
    neovide
    pavucontrol
    btrfs-assistant
    virtualenv
    (python3.withPackages (ps:
      with ps; [
      ]))
    krusader
    kdePackages.filelight
    vlc
    rnote
    (ollama.override {acceleration = "cuda";})
    distrobox
    zapzap
    ffmpeg-full
    imagemagick
    rustdesk
    protontricks
    wine
    wl-clipboard
    parsec-bin
    spotify
    openjdk19
    xournalpp
    git-crypt
    delta
    skrooge
    (blender.override {cudaSupport = true;})
    skypeforlinux
    floorp
    fh
    kalker
    gh
    jq
    electrum
    scrcpy
    android-tools
    minikube
    yt-dlp
    httpy-cli
    kshutdown
    config.nur.repos.milahu.vdhcoapp
    beeper
    nixpkgs-fmt
  ];

  programs.home-manager.enable = true;
}
