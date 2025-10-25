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
    mkBefore
    mkAfter
    mkOrder
    ;
in
{
  options = {
    zshConfig.enable = mkEnableOption "Enable zsh configuration";
  };
  config = mkIf config.zshConfig.enable {
    users.users.${username}.shell = pkgs.zsh;
    programs.zsh.enable = true;
    programs.pay-respects.enable = true;
    environment.systemPackages = with pkgs; [
      zsh-nix-shell
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
    ];

    environment.pathsToLink = [ "/share/zsh" ];

    hm = {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        completionInit = ""; # not comp init because antidote will handle it
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
          webcam = lib.mkIf config.dev.androidtools.enable "${lib.getExe pkgs.scrcpy} --v4l2-sink=/dev/video0 --orientation=0";
          vi = "nvim";
          vim = "nvim";
        };
        initContent = mkMerge [
          (mkBefore ''
            (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
            # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
            # Initialization code that may require console input (password prompts, [y/n]
            # confirmations, etc.) must go above this block; everything else may go below.
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi
            (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

            if [ -n "''${ZSH_PROFILE_STARTUP:+x}" ]
            then
              zmodload zsh/zprof
            fi
          '')
          (mkOrder 1000 ''
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
            flatpak_backup(){
              ${lib.getExe' pkgs.flatpak "flatpak"} list --app --show-details | \
              ${lib.getExe pkgs.gawk} '{print "${lib.getExe' pkgs.flatpak "flatpak"} install --assumeyes --user \""$2"\" \""$1}' | \
              ${lib.getExe' pkgs.coreutils "cut"} -d "/" -f1 | ${lib.getExe pkgs.gawk} '{print $0"\""}'
            }
            nix-quick(){
              ${lib.getExe pkgs.nix} flake init --template "https://flakehub.com/f/the-nix-way/dev-templates/*#$1"
            }
            flake-parts(){
              ${lib.getExe pkgs.nix} flake init -t github:hercules-ci/flake-parts
            }
            upgrade(){
              current_commit=$(sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos log -1 --pretty=%H)
            if [[ $1 == "--full" ]]
            then
              sudo ${lib.getExe pkgs.nix} flake update /etc/nixos --commit-lock-file
            else
              sudo ${lib.getExe pkgs.nix} flake lock \
                --update-input nixpkgs \
                --update-input lanzaboote \
                --update-input home-manager \
                --update-input plasma-manager \
                --update-input flatpaks \
                --update-input agenix \
                --commit-lock-file \
                /etc/nixos
            fi
            new_commit=$(sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos log -1 --pretty=%H)
             if [ "$current_commit" != "$new_commit" ]
             then
               ${lib.getExe pkgs.nh} os switch /etc/nixos
               if [ $? -eq 0 ]
            	    then
              	    echo ok
            	    else
              	    echo error
              	    oldStash=$(sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos rev-parse -q --verify refs/stash)
              	    sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos stash push --all -m "Stash changes before update"
              	    sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos reset --hard HEAD~
              	    newStash=$(sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos rev-parse -q --verify refs/stash)
              	    if [ "$oldStash" != "$newStash" ]
              	    then
                  	  sudo ${lib.getExe pkgs.git} --git-dir=/etc/nixos/.git --work-tree=/etc/nixos stash pop
               	  fi
              	fi
             else
            	  echo nothing to update
             fi
            }
            sshrm(){
              ARGS=$1
              # CHECK if only IP/HOSTNAME or user@IP/user@HOSTAME
              if [[ "$ARGS" =~ \@ ]]
              then
                 	# KEEP only things after @ (The IP or HOSTNAME)
                 	SRV=$(echo $ARGS | cut -d '@' -f2)
              else
                 	SRV="$ARGS"
              fi

              # REMOVE in known_hosts
              ssh-keygen -R $SRV

              # ASK to reconnect
              read -p "Reconnect ? IT WILL RUN \"ssh $ARGS\" ? (y/N) " RECO

              # CHECK ANSWSER
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
              # Récupère le serial number de la YubiKey branchée
              SERIAL=$(ykman list -s 2>/dev/null | head -1)

              if [ -z "$SERIAL" ]; then
                  echo "error: Aucune YubiKey détectée !" 1>&2
                  exit 1
              fi

              if [[ -L "/home/${username}/.config/git/config" ]]; then
                ${lib.getExe' pkgs.coreutils "cp"} --remove-destination "$(readlink -f /home/${username}/.config/git/config)" /home/${username}/.config/git/config
              fi

              # Détermine la clé SSH en fonction du serial number
              if [ "$SERIAL" = "18682465" ]; then
                  git config --global user.signingkey 2062A09259B7F6043C1AE8BA9AEBA130F4A6B1A7
              elif [ "$SERIAL" = "18682488" ]; then
                  git config --global user.signingkey EB3D34C78AEFF9626C4A4255E836B5CC4E27C9B0
              else
                  echo "error: YubiKey non reconnue : $SERIAL" 1>&2
                  return 1
              fi
            }

            # enable fzf
            [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
            #enable zoxide
            eval "$(${lib.getExe pkgs.zoxide} init zsh)"
            # enable nix-index
            source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

            # enable poetry completions
            fpath+=~/.zfunc

            # enable uv completions
            eval "$(${lib.getExe pkgs.uv} generate-shell-completion zsh)"
            eval "$(${lib.getExe' pkgs.uv "uvx"} --generate-shell-completion zsh)"
          '')
          (mkAfter ''
            if [ -n "$ZSH_PROFILE_STARTUP" ]
            then
              zprof
            fi
          '')
        ];

        localVariables = {
          POWERLEVEL9K_MODE = "nerdfont-v3"; # maybe better to ask p10k configure for the right value
          #config du prompt
          POWERLEVEL9K_CUSTOM_USER = "echo $USER";
          POWERLEVEL9K_CUSTOM_USER_ICON_BACKGROUND = 234;
          POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS = [
            "status"
            "background_jobs"
            "time"
            "battery"
          ];
          POWERLEVEL9K_LEFT_PROMPT_ELEMENTS = [
            "os_icon"
            "custom_user"
            "dir"
            "dir_writable"
            "virtualenv"
            "anaconda"
            "pyenv"
            "root_indicator"
            "vcs"
          ];
          #prompt multiligne
          POWERLEVEL9K_PROMPT_ADD_NEWLINE = true;
          POWERLEVEL9K_PROMPT_ON_NEWLINE = true;
          POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX = "\\u256d\\u2500 ";
          POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX = "\\u2570\\uf460 ";

          #config horloge calendrier pour prompt

          POWERLEVEL9K_TIME_FORMAT = "%D{\\ue383 %H:%M \\uf073 %d.%m.%y}";

          #config status
          POWERLEVEL9K_STATUS_OK_BACKGROUND = 232;
          POWERLEVEL9K_STATUS_OK_FOREGROUND = 46;
          POWERLEVEL9K_STATUS_ERROR_BACKGROUND = 232;
          POWERLEVEL9K_STATUS_ERROR_FOREGROUND = 196;

          #config batterie

          POWERLEVEL9K_BATTERY_CHARGING = "yellow";
          POWERLEVEL9K_BATTERY_CHARGED = "green";
          POWERLEVEL9K_BATTERY_DISCONNECTED = "$DEFAULT_COLOR";
          POWERLEVEL9K_BATTERY_LOW_THRESHOLD = "10";
          POWERLEVEL9K_BATTERY_LOW_COLOR = "red";
          POWERLEVEL9K_BATTERY_ICON = "\\uf1e6";

          #config indicateur root
          POWERLEVEL9K_ROOT_ICON = "\\uf198";
          POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND = 196;
          POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND = 232;

          #config indicateur de processus en arriere plan

          POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND = 232;
          POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND = 178;
          POWERLEVEL9K_INSTANT_PROMPT = "quiet";
        };

        antidote = {
          enable = true;
          plugins = [
            "Aloxaf/fzf-tab"
            "zsh-users/zsh-completions"
            "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
            "ohmyzsh/ohmyzsh path:plugins/sudo"
            "ohmyzsh/ohmyzsh path:plugins/git"
            "ohmyzsh/ohmyzsh path:plugins/command-not-found"
            "ohmyzsh/ohmyzsh path:plugins/common-aliases"
            "unixorn/fzf-zsh-plugin"
            "zsh-users/zsh-autosuggestions"
            "ohmyzsh/ohmyzsh path:lib/clipboard.zsh"
            "ohmyzsh/ohmyzsh path:lib/completion.zsh"
            "ohmyzsh/ohmyzsh path:lib/grep.zsh"
            "ohmyzsh/ohmyzsh path:lib/history.zsh"
            "ohmyzsh/ohmyzsh path:lib/directories.zsh"
            "ohmyzsh/ohmyzsh path:lib/functions.zsh"
            "ohmyzsh/ohmyzsh path:lib/key-bindings.zsh"
            "romkatv/powerlevel10k"
            "zdharma-continuum/fast-syntax-highlighting"
          ];
        };
      };
    };
  };
}
