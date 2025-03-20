{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    zshConfig.enable = mkEnableOption "Enable zsh configuration";
  };
  config = mkIf config.zshConfig.enable {
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
    ];

    programs.starship = {
      enable = true;
      # presets = ["tokyo-night"];
      settings = {
        format = ''
          ╭─ $hostname$os[](bg:#fcfcfc fg:#222626)$username[](bg:#769ff0 fg:#fcfcfc)$directory$direnv[](fg:#1d98f2 bg:#f67341)$git_branch$git_status$git_state[](fg:#f67341 bg:black) $kubernetes$docker_context$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$gleam$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$quarto$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$typst$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$nats$env_var$crystal$custom$sudo$jobs$container$shell
          ╰$character'';
        right_format = "[](fg:#0b0b0e)[$cmd_duration$status](bg:#0b0b0e)$time[](fg:#0b0b0e bg:white)$battery";
        palette = "catppuccin_mocha";
        cmd_duration = {
          min_time = 500;
        };
        character = {
          success_symbol = "[](bold white)";
          error_symbol = "[](bold red)";
        };
        direnv = {
          disabled = false;
          symbol = "";
          allowed_msg = "✅";
          not_allowed_msg = "❌";
          denied_msg = "🚫";
          loaded_msg = "🚀";
          unloaded_msg = "🛑";
          style = "fg:black bg:#1d98f2";
          format = "[$symbol$loaded/$allowed]($style)";
        };
        battery = {
          format = "[ $percentage $symbol ]($style bg:#0b0b0e )";
          charging_symbol = "";
          display = [
            {
              threshold = 25;
              style = "bold red";
            }
            {
              threshold = 50;
              style = "bold yellow";
            }
            {
              threshold = 75;
              style = "#aed13b";
            }
            {
              threshold = 100;
              style = "bold green";
            }
          ];
        };
        status = {
          success_symbol = "✅";
          disabled = false;
          style = "bg:#0b0b0e";
        };
        directory = {
          format = "[  $path $read_only ]($style)";
          style = "fg:black bg:#1d98f2";
          truncate_to_repo = false;
          fish_style_pwd_dir_length = 5;
          truncation_length = 3;
        };
        git_branch = {
          format = "[ $symbol $branch ]($style)";
          style = "fg:black bg:#f67341";
          symbol = "";
        };
        git_status = {
          format = "[$all_status$ahead_behind ]($style)";
          modified = "";
          style = "fg:black bg:#f67341";
          ahead = "⇡$${count}";
          diverged = "⇕⇡$${ahead_count}⇣$${behind_count}";
          behind = "⇣$${count}";
        };
        os = {
          disabled = false;
          format = "[ $symbol ]($style)";
          style = "bg:#222626";
        };
        palettes = {
          catppuccin_mocha = {
            base = "#1e1e2e";
            blue = "#89b4fa";
            crust = "#11111b";
            flamingo = "#f2cdcd";
            green = "#a6e3a1";
            lavender = "#b4befe";
            mantle = "#181825";
            maroon = "#eba0ac";
            mauve = "#cba6f7";
            overlay0 = "#6c7086";
            overlay1 = "#7f849c";
            overlay2 = "#9399b2";
            peach = "#fab387";
            pink = "#f5c2e7";
            red = "#f38ba8";
            rosewater = "#f5e0dc";
            sapphire = "#74c7ec";
            sky = "#89dceb";
            subtext0 = "#a6adc8";
            subtext1 = "#bac2de";
            surface0 = "#313244";
            surface1 = "#45475a";
            surface2 = "#585b70";
            teal = "#94e2d5";
            text = "#cdd6f4";
            yellow = "#f9e2af";
          };
        };
        time = {
          utc_time_offset = "local";
          disabled = false;
          format = "[](fg:#fcfcfc bg:#0b0b0e)[ $time ]($style)";
          style = "fg:#0b0b0e bg:#fcfcfc";
          use_12hr = false;
          time_format = "  %H:%M  %m.%d.%y  ";
        };
        username = {
          show_always = true;
          style_user = "fg:#000000 bg:#fcfcfc";
          format = "[ $user ]($style)";
        };
      };
    };

    hm = {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableCompletion = true;
        shellAliases = {
          du = lib.getExe pkgs.dust;
          cp = "${lib.getExe pkgs.xcp} -r";
          mv = "${lib.getExe' pkgs.coreutils "mv"} -vi";
          cd = "z"; # not using direct path because it is provided by zoxide
          sman = lib.getExe pkgs.tldr;
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
        };
        initExtra = ''
          export PATH="$PATH":"$HOME/.pub-cache/bin:$HOME/.cargo/bin"
          nshell(){
            local packages=("$@")
            local package_list=()

            for pkg in "''${packages[@]}"; do
              package_list+=("nixpkgs#$pkg")
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
          # enable fzf
          [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
          #enable zoxide
          eval "$(${lib.getExe pkgs.zoxide} init zsh)"
          # enable nix-index
          source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh

          # enable poetry completions
          fpath+=~/.zfunc
          autoload -Uz compinit && compinit

          # enable uv completions
          eval "$(${lib.getExe pkgs.uv} generate-shell-completion zsh)"
          eval "$(${lib.getExe' pkgs.uv "uvx"} --generate-shell-completion zsh)"
        '';

        zplug = {
          enable = true;
          plugins = [
            {
              name = "zsh-users/zsh-syntax-highlighting";
              tags = ["defer:2"];
            }

            #{ name = "plugins/git"; tags = [from:oh-my-zsh];}
            #{ name = "plugins/gitignore"; tags = [from:oh-my-zsh];}
            {
              name = "plugins/colored-man-pages";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "plugins/thefuck";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "plugins/sudo";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "plugins/command-not-found";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "plugins/common-aliases";
              tags = ["from:oh-my-zsh"];
            }
            {name = "unixorn/fzf-zsh-plugin";}
            {
              name = "zsh-users/zsh-autosuggestions";
              tags = ["depth:1"];
            }
            {
              name = "lib/clipboard";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/completion";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/grep";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/history";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/directories";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/functions";
              tags = ["from:oh-my-zsh"];
            }
            {
              name = "lib/key-bindings";
              tags = ["from:oh-my-zsh"];
            }
          ];
        };
      };
    };
  };
}