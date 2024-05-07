{
  config,
  pkgs,
  stateVersion,
  username,
  inputs,
  ...
}: {
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  imports = [
    inputs.flatpaks.homeManagerModules.nix-flatpak
    inputs.plasma-manager.homeManagerModules.plasma-manager
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
    blender
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
    pdfarranger
  ];
}
