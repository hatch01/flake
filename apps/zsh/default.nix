{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    getExe
    getExe'
    ;

  basePackages = with pkgs; [
    bat
    eza # Modern, maintained replacement for ls
    fd # Simple, fast and user-friendly alternative to find
    dust # du, but more intuitive
    duf # Disk Usage/Free Utility
    ripgrep # Utility that combines the usability of The Silver Searcher with the raw speed of grep
    zoxide # Fast cd command that learns your habits
    rip2 # rm, but more intuitive
    xcp # Extended cp(1)
    zsh-completions # Additional completion definitions for zsh
    nix-tree # Interactively browse a Nix store paths dependencies
    procs # Modern replacement for ps written in Rust
    snitch # friendlier ss / netstat for humans
  ];

  baseShellAliases = with pkgs; {
    du = getExe dust;
    df = getExe duf;
    ls = getExe eza;
    ll = "${getExe eza} -l";
    l = "${getExe eza} -la";
    cd = "z"; # provided by zoxide
    cp = "${getExe xcp} -r";
    mv = "${getExe' coreutils "mv"} -vi";
    rm = "${getExe rip2} --graveyard ~/.local/share/Trash";
    cat = getExe bat;
    slazygit = "sudo -E ${getExe lazygit}";
    search = "${getExe nh} search";
    clean = "${getExe nh} clean all";
    nix-history = "${getExe nix} profile history --profile /nix/var/nix/profiles/system";
    bkill = "fzf-kill"; # not using direct path because it is provided by fzf-zsh-plugin
    gitnix = "${getExe git} add . && ${getExe git} commit --amend --no-edit && ${getExe git} push --force";
    vi = "nvim";
    vim = "nvim";
    rip = "rip --graveyard ~/.local/share/Trash";
    sman = getExe tlrc;
    sgit = "sudo -E ${getExe git}";
    se = "sudo -E";
    update-old = "sudo ${getExe nixos-rebuild} switch --flake /etc/nixos --use-remote-sudo";
    update = "${getExe nh} os switch /etc/nixos";
    ps = "${getExe procs}";
  };

  fullShellAliases =
    with pkgs;
    baseShellAliases
    // {
      y = "yazi"; # yazi wrapper: cd into last browsed dir on exit
      stress = "for i in $(${getExe' coreutils "seq"} $(${getExe getconf} _NPROCESSORS_ONLN)); do ${getExe' coreutils "yes"} > /dev/null & done";
      webcam_back =
        lib.mkIf (config.dev.androidtools.enable or false)
          "${getExe scrcpy} --video-source=camera --camera-id=0 --camera-size=1920x1080 --v4l2-sink=/dev/video0 --no-playback";
      webcam_front =
        lib.mkIf (config.dev.androidtools.enable or false)
          "${getExe scrcpy} --video-source=camera --camera-id=1 --camera-size=1920x1080 --v4l2-sink=/dev/video0 --no-playback";
      dig = getExe doggo;
    };

  baseShellFunctions = with pkgs; ''
    nshell(){
        local packages=("$@")
        local package_list=()

        for pkg in "''${packages[@]}"; do
          package_list+=("n#$pkg")
        done

        NIXALLOW_UNFREE=1 ${getExe nix} shell --impure "''${package_list[@]}"
      }

      ccd() {
        cd $1 && ${getExe' ncurses "clear"}
      }
      cp_song() {
        ${getExe rsync} -var $1 $2
      }

      nix-quick(){
        ${getExe nix} flake init --template "https://flakehub.com/f/the-nix-way/dev-templates/*#$1"
      }
      flake-parts(){
        ${getExe nix} flake init -t github:hercules-ci/flake-parts
      }
      sshrm(){
        ARGS=$1
        if [[ "$ARGS" =~ \@ ]]
        then
            SRV=$(echo $ARGS | cut -d '@' -f2)
        else
            SRV="$ARGS"
        fi
        ssh-keygen -R $SRV
        read -p "Reconnect ? IT WILL RUN \"ssh $ARGS\" ? (y/N) " RECO
        if [[ "$RECO" == "y" ]]
        then
            ssh "$ARGS"
        fi
      }
  '';

  fullShellFunctions = baseShellFunctions + ''
    export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"

    ${./magellan_smart_ssh.sh}


    # yazi: cd into the directory browsed in yazi when it exits
    yazi() {
      local tmp="''${TMPDIR:-/tmp}/yazi-cwd.$$"
      command yazi --cwd-file "$tmp" "$@"
      if [[ -f "$tmp" ]]; then
        local cwd
        cwd="$(<$tmp)"
        if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      fi
    }
  '';

  baseShellInit = with pkgs; ''
    if [ -n "''${ZSH_PROFILE_STARTUP:+x}" ]
    then
      zmodload zsh/zprof
    fi

    source ${zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

    # enable fzf
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    # enable zoxide
    eval "$(${getExe zoxide} init zsh)"

    # ── completion init ───────────────────────────────────────────────────
    # zstyle must be set before compinit.
    zstyle ':completion::complete:*' use-cache on
    zstyle ':completion::complete:*' cache-path ~/.zsh/cache

    # fpath is already populated by /etc/zshenv via the NIX_PROFILES loop.
    # -C: skip security audit and dump regeneration entirely.
    # The dump is regenerated automatically on every nixos-rebuild (Nix store
    # paths in fpath change → dump is absent/stale on first shell after rebuild).
    # For a manual regen (e.g. after `nix profile install`), run: zinit
    autoload -Uz compinit
    compinit -C

    zinit() { autoload -Uz compinit && compinit -u && echo "compinit done" }

    # ── things that call compdef (must come after compinit) ───────────────
    # nix-index command-not-found handler registers a compdef internally.
    source ${nix-index}/etc/profile.d/command-not-found.sh

    source ${zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    source ${zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
    zsh-defer source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    zsh-defer source ${zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
    zsh-defer source ${zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    zsh-defer source ${zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
    zsh-defer source ${fzf-zsh-plugin}/share/zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

    if [ -n "$ZSH_PROFILE_STARTUP" ]
    then
      zprof
    fi
  '';
  fullShellInit =
    with pkgs;
    ''

      # ── fpath additions (must come before compinit) ──────────────────────
      # poetry completions
      fpath+=~/.zfunc

      # Cache uv/uvx completion files into a fpath directory.
      # Using fpath files (instead of `eval`/`source`) means compinit picks
      # them up naturally — no `compdef` call needed after compinit.
      # The stamp file holds the current uv store path; it changes on every
      # `nix` upgrade, which is the only time the completions need regenerating.
      _uv_comp_dir="$HOME/.zsh/completions"
      _uv_store_path="${getExe uv}"
      _uv_comp_stamp="$_uv_comp_dir/.stamp"
      if [[ "$(cat "$_uv_comp_stamp" 2>/dev/null)" != "$_uv_store_path" ]]; then
        mkdir -p "$_uv_comp_dir"
        ${getExe uv} generate-shell-completion zsh >| "$_uv_comp_dir/_uv"
        ${getExe' uv "uvx"} --generate-shell-completion zsh >| "$_uv_comp_dir/_uvx"
        echo "$_uv_store_path" >| "$_uv_comp_stamp"
      fi
      fpath=("$_uv_comp_dir" $fpath)
    ''
    + baseShellInit; # baseShellInit go after for performance of zsh start time
in
{
  options = {
    zshConfig.enable = mkEnableOption "Enable zsh configuration";
    zshConfig.enableFull = mkEnableOption "Enable full zsh configuration";
  };
  config = mkMerge [
    (mkIf config.zshConfig.enable {
      users.users.root.shell = pkgs.zsh;
      users.users.${username}.shell = pkgs.zsh;

      programs.zsh = {
        enable = true;
        autosuggestions.enable = false;
        enableCompletion = false;
        enableBashCompletion = true;
        shellAliases = baseShellAliases;
        shellInit = baseShellFunctions;
        interactiveShellInit = baseShellInit;
        ohMyZsh = {
          enable = true;
          plugins = [
            "git"
            "colored-man-pages"
            "sudo"
            "command-not-found"
            "common-aliases"
          ];
        };
        promptInit = with pkgs; ''
          source ${zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          export POWERLEVEL9K_MODE="nerdfont-v3"
          export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time battery)
          export POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir dir_writable virtualenv anaconda pyenv root_indicator vcs)
          export POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
          export POWERLEVEL9K_PROMPT_ON_NEWLINE=true
          export POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=$'\u256d\u2500 '
          export POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=$'\u2570\uf460 '
          export POWERLEVEL9K_TIME_FORMAT='%D{\ue383 %H:%M \uf073 %d.%m.%y}'
          export POWERLEVEL9K_STATUS_OK_BACKGROUND=232
          export POWERLEVEL9K_STATUS_OK_FOREGROUND=46
          export POWERLEVEL9K_STATUS_ERROR_BACKGROUND=232
          export POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
          export POWERLEVEL9K_BATTERY_CHARGING="yellow"
          export POWERLEVEL9K_BATTERY_CHARGED="green"
          export POWERLEVEL9K_BATTERY_DISCONNECTED="$DEFAULT_COLOR"
          export POWERLEVEL9K_BATTERY_LOW_THRESHOLD="10"
          export POWERLEVEL9K_BATTERY_LOW_COLOR="red"
          export POWERLEVEL9K_BATTERY_ICON=$'\uf1e6'
          export POWERLEVEL9K_ROOT_ICON=$'\uf198'
          export POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND=196
          export POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND=232
          export POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=232
          export POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=178
          export POWERLEVEL9K_INSTANT_PROMPT="quiet"
          typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
        '';
      };

      hma.programs.zellij = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        exitShellOnExit = true;
        settings = {
          show_startup_tips = false;
          theme = "catppuccin-mocha";
        };
      };

      hm.programs.btop.settings.color_theme =
        "/home/${username}/.config/btop/themes/catppuccin_mocha.theme";
      hmr.programs.btop.settings.color_theme = "/root/.config/btop/themes/catppuccin_mocha.theme";
      hma = {
        programs.btop.enable = true;
        home = {
          file.".config/btop/themes" = {
            source =
              pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "btop";
                tag = "1.0.0";
                sha256 = "sha256-J3UezOQMDdxpflGax0rGBF/XMiKqdqZXuX4KMVGTxFk=";
              }
              + "/themes";
          };
        };
      };

      environment.systemPackages = basePackages;
      environment.pathsToLink = [ "/share/zsh" ];

      hma.programs.zsh.enable = true; # only needed to allow home manager to autostart zellij
      hma.programs.bash.enable = true; # only needed to allow home manager to autostart zellij
    })
    (mkIf config.zshConfig.enableFull {
      programs.pay-respects.enable = true;
      environment.systemPackages =
        basePackages
        ++ (with pkgs; [
          bandwhich # CLI utility for displaying current network utilization
          bottom # Cross-platform graphical process/system monitor with a customizable interface
          btdu # Sampling disk usage profiler for btrfs
          caligula # User-friendly, lightweight TUI for disk imaging
          detox # Utility designed to clean up filenames
          doggo # Command-line DNS Client for Humans. Written in Golang
          gitoxide # Command-line application for interacting with git repositories
          grex # Command-line tool for generating regular expressions from user-provided test cases
          hyperfine # Command-line benchmarking tool
          jless # Command-line pager for JSON data
          lazysql # Cross-platform TUI database management tool written in Go
          ouch # Command-line utility for easily compressing and decompressing files and directories
          parallel # Shell tool for executing jobs in parallel
          pbzip2 # Parallel implementation of bzip2 for multi-core machines
          ripgrep-all # Ripgrep, but also search in PDFs, E-Books, Office documents, zip, tar.gz, and more
          sd # Intuitive find & replace CLI (sed alternative)
          serpl # Simple terminal UI for search and replace, ala VS Code
          silicon # Create beautiful image of your source code
          skim # Command-line fuzzy finder written in Rust
          sshfs # FUSE-based filesystem that allows remote filesystems to be mounted over SSH
          tokei # Count your code, quickly
          w3m # Text-mode web browser
          # Delete a file or folder from btrfs live fs and all matching snapshots
          (writeShellApplication {
            name = "brm";
            runtimeInputs = [
              btrfs-progs
              util-linux
              coreutils
            ];
            text = builtins.readFile ./brm.sh;
          })
          (writeShellApplication {
            name = "zellij-probe";
            text = builtins.readFile ./zellij-probe.sh;
          })
        ]);

      programs.zsh = {
        shellInit = fullShellFunctions;
        interactiveShellInit = fullShellInit;
      };
    })
  ];
}
