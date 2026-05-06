{
  config,
  pkgs,
  lib,
  username,
  stable,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    optionals
    mkIf
    getExe
    getExe'
    ;
in
{
  options = {
    zshConfig.enable = mkEnableOption "Enable zsh configuration";
  };
  config = mkIf config.zshConfig.enable {
    users.users.root.shell = pkgs.zsh;
    users.users.${username}.shell = pkgs.zsh;
    programs.pay-respects.enable = true;
    environment.systemPackages =
      with pkgs;
      [
        w3m
        ripgrep
        ripgrep-all
        zoxide
        eza
        procs
        tokei
        bandwhich
        dust
        duf
        sd
        hyperfine
        fd
        grex
        detox
        xcp
        silicon
        ouch
        nix-tree
        bottom
        parallel
        pbzip2
        caligula
        zellij
        zsh-completions
        jless
        fzf-zsh-plugin
        sshfs
        gitoxide
        btdu
        yazi
        doggo
      ]
      ++ optionals (!stable) (
        with pkgs;
        [
          snitch
        ]
      );

    environment.pathsToLink = [ "/share/zsh" ];

    programs.zsh = {
      enable = true;
      autosuggestions.enable = false;
      enableCompletion = false;
      enableBashCompletion = true;
      shellAliases = with pkgs; {
        du = getExe dust;
        df = getExe duf;
        cp = "${getExe xcp} -r";
        mv = "${getExe' coreutils "mv"} -vi";
        cd = "z"; # not using direct path because it is provided by zoxide
        sman = getExe tlrc;
        cat = getExe bat;
        ls = getExe eza;
        ll = "${getExe eza} -l";
        l = "${getExe eza} -la";
        rm = "${getExe rip2} --graveyard ~/.local/share/Trash";
        sgit = "sudo -E ${getExe git}";
        se = "sudo -E";
        slazygit = "sudo -E ${getExe lazygit}";
        # nixos specific command
        update-old = "sudo ${getExe nixos-rebuild} switch --flake /etc/nixos --use-remote-sudo";
        update = "${getExe nh} os switch /etc/nixos";
        nix-history = "${getExe nix} profile history --profile /nix/var/nix/profiles/system";
        yay = "upgrade";
        bro = "upgrade";
        search = "${getExe nh} search";
        clean = "${getExe nh} clean all";
        stress = "for i in $(${getExe' coreutils "seq"} $(${getExe getconf} _NPROCESSORS_ONLN)); do ${getExe' coreutils "yes"} > /dev/null & done";
        bkill = "fzf-kill"; # not using direct path because it is provided by fzf-zsh-plugin
        gitnix = "${getExe git} add . && ${getExe git} commit --amend --no-edit && ${getExe git} push --force";
        ps = "${getExe procs}";
        webcam = lib.mkIf (config.dev.androidtools.enable or false
        ) "${getExe scrcpy} --v4l2-sink=/dev/video0 --orientation=0";
        vi = "nvim";
        vim = "nvim";
        rip = "rip --graveyard ~/.local/share/Trash";
        dig = getExe doggo;
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

      shellInit = with pkgs; ''
        export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
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

        # Helper function to select SSH host with fzf
        _select_ssh_host() {
          local query="$1"
          local hosts
          hosts=$(grep -E '^Host ' ~/.ssh/config | awk '{print $2}')

          if [[ -n $query ]]; then
            local server=$(echo "$hosts" | grep -i "$query")
            local count=$(echo "$server" | wc -l)
            if [[ $count -eq 1 ]]; then
              echo "$server"
              return 0
            fi
            echo "$hosts" | fzf --query="$query"
          else
            echo "$hosts" | fzf
          fi
        }

        s() {
          local no_www=0
          local OPTIND opt

          while getopts "w" opt; do
            case $opt in
              w) no_www=1 ;;
              *) echo "Usage: s [-w] [server]" >&2; return 1 ;;
            esac
          done
          shift $((OPTIND - 1))
          local server=$(_select_ssh_host "$1")
          if [[ -n $server ]]; then
            if [[ $no_www -eq 1 ]]; then
              ssh "$server"
            else
              ssh -t "$server" "sudo su - www"
            fi
          fi
        }

        smount() {
          local remote_user="www"
          local OPTIND opt

          # Parse les options
          while getopts "u:" opt; do
            case $opt in
              u) remote_user="$OPTARG" ;;
              *) echo "Usage: smount [-u user] [server]" >&2; return 1 ;;
            esac
          done
          shift $((OPTIND - 1))

          # Toujours passer par fzf pour matcher le serveur
          local query="$1"
          local server=$(_select_ssh_host "$query")
          if [[ -z "$server" ]]; then
            echo "No server selected" >&2
            return 1
          fi

          # Extrait les infos de la config SSH (supprime stderr)
          local ssh_config=$(ssh -G "$server" 2>/dev/null)
          local ssh_user=$(echo "$ssh_config" | awk '/^user / {print $2}')
          local ssh_host=$(echo "$ssh_config" | awk '/^hostname / {print $2}')
          local proxy_jump=$(echo "$ssh_config" | awk '/^proxyjump / {print $2}')

          # Utilise uniquement le dernier segment après le dernier /
          local server_name="''${ssh_host##*/}"
          local mount_point="/tmp/$server_name"
          mkdir -p "$mount_point"

          # Check si déjà monté
          if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "✓ Already mounted at $mount_point"
            cd "$mount_point"
            return 0
          fi

          # Construit la commande sftp_server
          local sftp_cmd
          if [[ "$remote_user" == "$ssh_user" ]]; then
            sftp_cmd="/usr/libexec/openssh/sftp-server"
            echo "📁 Mounting $server_name as $remote_user (no sudo)..."
          else
            sftp_cmd="sudo -u $remote_user /usr/libexec/openssh/sftp-server"
            echo "📁 Mounting $server_name as $remote_user (with sudo)..."
          fi

          # Monte avec ProxyCommand si nécessaire
          local mount_result
          if [[ -n "$proxy_jump" ]]; then
            echo "🔧 Using ProxyJump: $proxy_jump"
            sshfs "$ssh_user@$ssh_host:/" "$mount_point" \
              -o ProxyCommand="ssh -W %h:%p $proxy_jump" \
              -o sftp_server="$sftp_cmd" \
              -o reconnect \
              -o ServerAliveInterval=15
            mount_result=$?
          else
            sshfs "$ssh_user@$ssh_host:/" "$mount_point" \
              -o sftp_server="$sftp_cmd" \
              -o reconnect \
              -o ServerAliveInterval=15
            mount_result=$?
          fi

          if [[ $mount_result -eq 0 ]]; then
            echo "✓ Mounted at $mount_point"
            cd "$mount_point"
          else
            echo "✗ Failed to mount" >&2
            echo ""
            echo "💡 Debug: Try this command manually:"
            if [[ -n "$proxy_jump" ]]; then
              echo "   sshfs $ssh_user@$ssh_host:/ $mount_point \\"
              echo "     -o ProxyCommand=\"ssh -W %h:%p $proxy_jump\" \\"
              echo "     -o sftp_server=\"$sftp_cmd\" -v"
            else
              echo "   sshfs $ssh_user@$ssh_host:/ $mount_point \\"
              echo "     -o sftp_server=\"$sftp_cmd\" -v"
            fi
            return 1
          fi
        }

        sumount() {
          local server="$1"

          # Si pas de serveur spécifié, utilise fzf sur les montages existants
          if [[ -z "$server" ]]; then
            local mounted=$(find /tmp -maxdepth 1 -type d -exec mountpoint -q {} \; -print 2>/dev/null | xargs -n1 basename)
            if [[ -z "$mounted" ]]; then
              echo "No mounted servers found in /tmp" >&2
              return 1
            fi
            server=$(echo "$mounted" | fzf --prompt="Select server to unmount: ")
            if [[ -z "$server" ]]; then
              echo "No server selected" >&2
              return 1
            fi
          fi

          local mount_point="/tmp/$server"
          if mountpoint -q "$mount_point" 2>/dev/null; then
            fusermount -u "$mount_point" 2>/dev/null || umount "$mount_point"
            echo "✓ Unmounted $mount_point"
          else
            echo "⚠ Not mounted: $mount_point"
          fi
        }

       eval "$(${getExe zellij} setup --generate-auto-start zsh)"
      '';

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

      interactiveShellInit = with pkgs; ''
        if [ -n "''${ZSH_PROFILE_STARTUP:+x}" ]
        then
          zmodload zsh/zprof
        fi

        source ${zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

        # enable fzf
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
        # enable zoxide
        eval "$(${getExe zoxide} init zsh)"

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
    };
  };
}
