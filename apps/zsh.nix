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
    environment.systemPackages = with pkgs; [
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
    ];

    environment.pathsToLink = [ "/share/zsh" ];

    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      shellAliases = {
        du = lib.getExe pkgs.dust;
        df = lib.getExe pkgs.duf;
        cp = "${lib.getExe pkgs.xcp} -r";
        mv = "${lib.getExe' pkgs.coreutils "mv"} -vi";
        cd = "z"; # not using direct path because it is provided by zoxide
        sman = lib.getExe pkgs.tlrc;
        cat = lib.getExe pkgs.bat;
        ls = lib.getExe pkgs.eza;
        ll = "${lib.getExe pkgs.eza} -l";
        l = "${lib.getExe pkgs.eza} -la";
        rm = "${lib.getExe' pkgs.trash-cli "trash-put"}";
        sgit = "sudo -E ${lib.getExe pkgs.git}";
        se = "sudo -E";
        slazygit = "sudo -E ${lib.getExe pkgs.lazygit}";
        # nixos specific command
        update-old = "sudo ${lib.getExe pkgs.nixos-rebuild} switch --flake /etc/nixos --use-remote-sudo";
        update = "${lib.getExe pkgs.nh} os switch /etc/nixos";
        nix-history = "${lib.getExe pkgs.nix} profile history --profile /nix/var/nix/profiles/system";
        yay = "upgrade";
        bro = "upgrade";
        search = "${lib.getExe pkgs.nh} search";
        clean = "${lib.getExe pkgs.nh} clean all";
        stress = "for i in $(${lib.getExe' pkgs.coreutils "seq"} $(${lib.getExe pkgs.getconf} _NPROCESSORS_ONLN)); do ${lib.getExe' pkgs.coreutils "yes"} > /dev/null & done";
        bkill = "fzf-kill"; # not using direct path because it is provided by fzf-zsh-plugin
        gitnix = "${lib.getExe pkgs.git} add . && ${lib.getExe pkgs.git} commit --amend --no-edit && ${lib.getExe pkgs.git} push --force";
        ps = "${lib.getExe pkgs.procs}";
        webcam = lib.mkIf (config.dev.androidtools.enable or false
        ) "${lib.getExe pkgs.scrcpy} --v4l2-sink=/dev/video0 --orientation=0";
        vi = "nvim";
        vim = "nvim";
      };
      promptInit = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        export POWERLEVEL9K_MODE="nerdfont-v3"
        export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs time battery)
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

      shellInit = ''
        export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
        nshell(){
          local packages=("$@")
          local package_list=()

          for pkg in "''${packages[@]}"; do
            package_list+=("n#$pkg")
          done

          NIXPKGS_ALLOW_UNFREE=1 ${lib.getExe pkgs.nix} shell --impure "''${package_list[@]}"
        }

        ccd() {
          cd $1 && ${lib.getExe' pkgs.ncurses "clear"}
        }
        cp_song() {
          ${lib.getExe pkgs.rsync} -var $1 $2
        }

        nix-quick(){
          ${lib.getExe pkgs.nix} flake init --template "https://flakehub.com/f/the-nix-way/dev-templates/*#$1"
        }
        flake-parts(){
          ${lib.getExe pkgs.nix} flake init -t github:hercules-ci/flake-parts
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

        s() {
          local server
          local query="$1"
          local hosts
          hosts=$(grep -E '^Host ' ~/.ssh/config | awk '{print $2}')

          if [[ -n $query ]]; then
            server=$(echo "$hosts" | grep -i "$query")
            count=$(echo "$server" | wc -l)
            if [[ $count -eq 1 ]]; then
              ssh "$server"
              return
            fi
            server=$(echo "$hosts" | fzf --query="$query")
          else
            server=$(echo "$hosts" | fzf)
          fi

          if [[ -n $server ]]; then
            ssh "$server"
          fi
        }

        upkey() {
          SERIAL=$(ykman list -s 2>/dev/null | head -1)
          if [ -z "$SERIAL" ]; then
              echo "error: Aucune YubiKey détectée !" 1>&2
              exit 1
          fi
          if [[ -L "/home/${username}/.config/git/config" ]]; then
            ${lib.getExe' pkgs.coreutils "cp"} --remove-destination "$(readlink -f /home/${username}/.config/git/config)" /home/${username}/.config/git/config
          fi
          if [ "$SERIAL" = "18682465" ]; then
              git config --global user.signingkey 2062A09259B7F6043C1AE8BA9AEBA130F4A6B1A7
          elif [ "$SERIAL" = "18682488" ]; then
              git config --global user.signingkey EB3D34C78AEFF9626C4A4255E836B5CC4E27C9B0
          else
              echo "error: YubiKey non reconnue : $SERIAL" 1>&2
              return 1
          fi
        }
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

      interactiveShellInit = ''
        if [ -n "''${ZSH_PROFILE_STARTUP:+x}" ]
        then
          zmodload zsh/zprof
        fi

        source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh

        # enable fzf
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
        # enable zoxide
        eval "$(${lib.getExe pkgs.zoxide} init zsh)"
        # enable nix-index
        source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

        # enable poetry completions
        fpath+=~/.zfunc

        # enable uv completions
        eval "$(${lib.getExe pkgs.uv} generate-shell-completion zsh)"
        eval "$(${lib.getExe' pkgs.uv "uvx"} --generate-shell-completion zsh)"

        zstyle ':completion::complete:*' use-cache on
        zstyle ':completion::complete:*' cache-path ~/.zsh/cache

        autoload -Uz compinit
        compinit -u

        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
        zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        zsh-defer source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh
        zsh-defer source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        zsh-defer source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
        zsh-defer source ${pkgs.fzf-zsh-plugin}/share/zsh/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

        if [ -n "$ZSH_PROFILE_STARTUP" ]
        then
          zprof
        fi
      '';
    };
  };
}
