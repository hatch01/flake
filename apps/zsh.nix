{ config, pkgs, ...}:

{
  home.packages = with pkgs; [
    zsh-nix-shell
    w3m
    ripgrep
    zoxide
    eza
    procs
    tokei
    bandwhich
    dust
    sd
    hyperfine
    fd
    grex
    detox
  ];
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    shellAliases = {
      du = "dust";
      cp = "cp -rvi";
      mv = "mv -vi";
      cd = "z";
      sman = "tldr";
      cat = "bat";
      ls = "eza";
      ll = "eza -l";
      l = "eza -la";
      rm = "trash-put";
      sgit = "sudo -E git";
      se = "sudo -E";
      slazygit = "sudo -E lazygit";
# nixos specific command
      update-old = "sudo nixos-rebuild switch --flake /etc/nixos --use-remote-sudo";
      update = "nh os switch /etc/nixos";
      yay = "upgrade";
      bro= "upgrade";
      search = "nh search";
      clean = "nh clean all";
      stress = "for i in $(seq $(getconf _NPROCESSORS_ONLN)); do yes > /dev/null & done";
      bkill="fzf-kill";
      gitnix = "git add . && git commit --amend --no-edit && git push --force";
      ps="procs";
      webcam="scrcpy --v4l2-sink=/dev/video0 --rotation=0";

    };
    initExtraFirst = ''
    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
    '';
    initExtra = ''
    export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
    cp_song() {
        rsync -var $1 $2
      }
    rmarkdown() {
      markdown2-3.6 $1 | w3m -T text/html
    }
    flatpak_backup(){
      flatpak list --app --show-details | \
        awk '{print "flatpak install --assumeyes --user \""$2"\" \""$1}' | \
        cut -d "/" -f1 | awk '{print $0"\""}'
    }
    nix-quick(){
	nix flake new --template github:the-nix-way/dev-templates#$1 $2
    }
    flake-parts(){
	nix flake init -t github:hercules-ci/flake-parts
    }
    upgrade(){
	current_commit=$(sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos log -1 --pretty=%H) 
	if [[ $1 == "--full" ]]
	then
	  sudo nix flake update /etc/nixos --commit-lock-file 
	else
	  sudo nix flake lock \
	    --update-input nixpkgs \
	    --update-input lanzaboote \
	    --update-input home-manager \
	    --update-input plasma-manager \
	    --update-input flatpaks \
	    --update-input agenix \
	    --commit-lock-file \
	    /etc/nixos
	fi
	new_commit=$(sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos log -1 --pretty=%H)
	if [ "$current_commit" != "$new_commit" ]
	then
	  update
	  if [ $? -eq 0 ]
  	  then
    	    echo ok
  	  else     
    	    echo error
    	      oldStash=$(sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos rev-parse -q --verify refs/stash)
    	      sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos stash push --all -m "Stash changes before update"
    	      sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos reset --hard HEAD~
    	      newStash=$(sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos rev-parse -q --verify refs/stash)
    	      if [ "$oldStash" != "$newStash" ]
    	      then
        	sudo git --git-dir=/etc/nixos/.git --work-tree=/etc/nixos stash pop
     	      fi
    	  fi
	else
  	  echo nothing to update
	fi
    }
    # enable fzf
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    #enable zoxide
    eval "$(zoxide init zsh)"
    '';

    zplug = {
      enable = true;
      plugins = [
      { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; }
      { name = "zsh-users/zsh-syntax-highlighting"; tags = [defer:2]; }

      #{ name = "plugins/git"; tags = [from:oh-my-zsh];}
      #{ name = "plugins/gitignore"; tags = [from:oh-my-zsh];}
      { name = "plugins/colored-man-pages"; tags = [from:oh-my-zsh];}
      { name = "plugins/thefuck"; tags = [from:oh-my-zsh];}
      { name = "plugins/sudo"; tags = [from:oh-my-zsh];}
      { name = "plugins/command-not-found"; tags = [from:oh-my-zsh];}
      { name = "plugins/common-aliases"; tags = [from:oh-my-zsh];}
      { name = "unixorn/fzf-zsh-plugin";}
      { name = "zsh-users/zsh-autosuggestions"; tags = [depth:1];}
      { name = "lib/clipboard"; tags = [from:oh-my-zsh];}
      { name = "lib/completion"; tags = [from:oh-my-zsh];}
      { name = "lib/grep"; tags = [from:oh-my-zsh];}
      { name = "lib/history"; tags = [from:oh-my-zsh];}
      { name = "lib/directories"; tags = [from:oh-my-zsh];}
      { name = "lib/functions"; tags = [from:oh-my-zsh];}
      { name = "lib/key-bindings"; tags = [from:oh-my-zsh];}
      ];
    };

    localVariables = {
      POWERLEVEL9K_MODE="nerdfont-v3"; #maybe better to ask p10k configure for the right value
#config du prompt
        POWERLEVEL9K_CUSTOM_USER="echo $USER";
      POWERLEVEL9K_CUSTOM_USER_ICON_BACKGROUND=234;
      POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=[ "status" "background_jobs" "time" "battery" ];
      POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=[ "os_icon" "custom_user" "dir" "dir_writable" "virtualenv" "anaconda" "pyenv" "root_indicator" "vcs" ];
#prompt multiligne
      POWERLEVEL9K_PROMPT_ADD_NEWLINE=true;
      POWERLEVEL9K_PROMPT_ON_NEWLINE=true;
      POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="\\u256d\\u2500 ";
      POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="\\u2570\\uf460 ";

#config horloge calendrier pour prompt

      POWERLEVEL9K_TIME_FORMAT="%D{\\ue383 %H:%M \\uf073 %d.%m.%y}";

#config status
      POWERLEVEL9K_STATUS_OK_BACKGROUND=232;
      POWERLEVEL9K_STATUS_OK_FOREGROUND=46;
      POWERLEVEL9K_STATUS_ERROR_BACKGROUND=232;
      POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196;

#config batterie

      POWERLEVEL9K_BATTERY_CHARGING="yellow";
      POWERLEVEL9K_BATTERY_CHARGED="green";
      POWERLEVEL9K_BATTERY_DISCONNECTED="$DEFAULT_COLOR";
      POWERLEVEL9K_BATTERY_LOW_THRESHOLD="10";
      POWERLEVEL9K_BATTERY_LOW_COLOR="red";
      POWERLEVEL9K_BATTERY_ICON="\\uf1e6";

#config indicateur root
      POWERLEVEL9K_ROOT_ICON="\\uf198";
      POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND=196;
      POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND=232;

#config indicateur de processus en arriere plan

      POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=232;
      POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=178;
      POWERLEVEL9K_INSTANT_PROMPT="quiet";
    };
  };
}
