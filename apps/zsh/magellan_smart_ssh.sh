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
          local no_zellij=${S_NO_ZELLIJ:-0}

          _s_help() {
            print -r "Usage: s [options] [server]

            Options:
            -w, --no-www      Connect directly as the SSH user (skip 'sudo su - www')
              -z, --no-zellij   Disable Zellij integration (standard SSH / sudo session)
                -h, --help        Show this help message

                Environment:
                S_NO_ZELLIJ=1     Disable Zellij by default for all connections

                Arguments:
                [server]          Target server (fuzzy search via fzf if omitted or partial)"
              }

              while [[ $# -gt 0 ]]; do
                case "$1" in
                  -h|--help)
                    _s_help
                    return 0
                ;;
                  -w|--no-www)
                    no_www=1
                    shift
                ;;
                  -z|--no-zellij)
                    no_zellij=1
                    shift
                ;;
                  -wz|-zw)
                    no_www=1
                    no_zellij=1
                    shift
                ;;
                  --)
                    shift
                    break
                ;;
                  -*)
                    echo "Unknown option: $1" > &2
                    _s_help > &2
                    return 1
                ;;
                  *)
                    break
                ;;
                esac
              done

              local server=$(_select_ssh_host "$1")
                if [[ -z "$server" ]]; then
                  return 1
                fi

                # Si Zellij est désactivé (flag -z ou S_NO_ZELLIJ=1)
                if (( no_zellij )); then
                  if [[ $no_www -eq 1 ]]; then
                    ssh "$server"
                    else
                      ssh -t "$server" "sudo su - www"
                    fi
                    return $?
                  fi

                  # ── 1. Gestion du cache local et auto-update de Zellij statique ────
                  local cache_dir="$HOME/.cache/zellij-static"
                  local local_bin="$cache_dir/zellij"
                  local stamp_file="$cache_dir/.last_update_check"
                  local zellij_url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
                  mkdir -p "$cache_dir"

                  local now=$(date +%s)
                    local last_check=$(stat -c %Y "$stamp_file" 2 > /dev/null || echo 0)

                      # Si le binaire local n'existe pas, premier téléchargement synchrone
                      if [[ ! -x "$local_bin" ]]; then
                        echo "📥 Premier téléchargement de Zellij statique..."
                        local tmp_init=$(mktemp -d "/tmp/zellij-init.XXXXXX")
                          if curl -sSL --connect-timeout 5 --max-time 60 "$zellij_url" -o "$tmp_init/zellij.tar.gz" && tar -xzf "$tmp_init/zellij.tar.gz" -C "$tmp_init" 2 > /dev/null; then
                            mv "$tmp_init/zellij" "$local_bin"
                            chmod 755 "$local_bin"
                            touch "$stamp_file"
                            else
                              echo "⚠ Impossible de télécharger Zellij (hors-ligne ou GitHub indisponible)." > &2
                            fi
                            rm -rf "$tmp_init"
                            elif (( now - last_check > 604800 )); then
                            # Plus de 7 jours : vérification / mise à jour asynchrone en arrière-plan (non-bloquant)
                            touch "$stamp_file"
                            (
                              local tmp_bg=$(mktemp -d "/tmp/zellij-update.XXXXXX")
                                if curl -sSL --connect-timeout 4 --max-time 45 "$zellij_url" -o "$tmp_bg/zellij.tar.gz" 2 > /dev/null && tar -xzf "$tmp_bg/zellij.tar.gz" -C "$tmp_bg" 2 > /dev/null; then
                                  if [[ -x "$tmp_bg/zellij" ]]; then
                                    mv "$tmp_bg/zellij" "$local_bin"
                                    chmod 755 "$local_bin"
                                  fi
                                fi
                                rm -rf "$tmp_bg"
                                ) > /dev/null 2 > &1 &!
                              fi

                              # ── 2. Déploiement et exécution sur le serveur distant ───────────────
                              local ssh_opts=(-o ControlMaster=auto -o ControlPersist=60s -o ControlPath="/tmp/ssh-%C")

                                if [[ -x "$local_bin" ]]; then
                                  local local_ver=$("$local_bin" --version 2 > /dev/null)

                                    # Arbre de décision pour trouver un répertoire inscriptible et exécutable (sans noexec)
                                    # Exécution de zellij-probe.sh sur le serveur distant
                                    local remote_dir
                                    remote_dir=$(ssh "${ssh_opts[@]}" "$server" "bash -s" < zellij-probe 2 > /dev/null | grep '^DIR:' | head -n1 | cut -d: -f2-)

                                      if [[ -n "$remote_dir" ]]; then
                                        local remote_bin="$remote_dir/zellij"
                                        local remote_sh="$remote_dir/shell"
                                        local remote_cfg="$remote_dir/config.kdl"

                                        # Vérifier si zellij est présent avec la bonne version et ses wrappers
                                        if ! ssh "${ssh_opts[@]}" "$server" "test -x '$remote_bin' && [ \"\$('$remote_bin' --version 2 > /dev/null)\" = '$local_ver' ] && test -x '$remote_sh' && test -f '$remote_cfg'" 2 > /dev/null; then
                                          echo "📤 Synchronisation de Zellij ($local_ver) vers $server:$remote_dir..."
                                          cat "$local_bin" | ssh "${ssh_opts[@]}" "$server" "cat > '$remote_bin' && chmod 755 '$remote_bin' && printf '#!/bin/sh\nexec sudo su - www\n' > '$remote_sh' && chmod 755 '$remote_sh' && printf 'default_shell \"%s\"\n' '$remote_sh' > '$remote_cfg'"
                                        fi

                                        # Lancement de Zellij avec rattachement de session
                                        if [[ $no_www -eq 1 ]]; then
                                          ssh "${ssh_opts[@]}" -t "$server" "'$remote_bin' attach -c main || exec \$SHELL -l"
                                          else
                                            ssh "${ssh_opts[@]}" -t "$server" "'$remote_bin' --config '$remote_cfg' attach -c main-www || sudo su - www"
                                          fi
                                          return $?
                                          else
                                            echo "⚠ Aucun répertoire exécutable trouvé (noexec). Connexion standard..." > &2
                                          fi
                                        fi

                                        # Repli sur le shell standard si aucun binaire Zellij n'a pu être obtenu ou déployé
                                        if [[ $no_www -eq 1 ]]; then
                                          ssh "$server"
                                          else
                                            ssh -t "$server" "sudo su - www"
                                          fi
                                        }

                                        smount() {
                                          local remote_user="www"
                                          local OPTIND opt

                                          # Parse les options
                                          while getopts "u:" opt; do
                                            case $opt in
                                              u) remote_user="$OPTARG" ;;
                                              *) echo "Usage: smount [-u user] [server]" > &2; return 1 ;;
                                            esac
                                          done
                                          shift $((OPTIND - 1))

                                          # Toujours passer par fzf pour matcher le serveur
                                          local query="$1"
                                          local server=$(_select_ssh_host "$query")
                                            if [[ -z "$server" ]]; then
                                              echo "No server selected" > &2
                                              return 1
                                            fi

                                            # Extrait les infos de la config SSH (supprime stderr)
                                            local ssh_config=$(ssh -G "$server" 2 > /dev/null)
                                              local ssh_user=$(echo "$ssh_config" | awk '/^user / {print $2}')
                                                local ssh_host=$(echo "$ssh_config" | awk '/^hostname / {print $2}')
                                                  local proxy_jump=$(echo "$ssh_config" | awk '/^proxyjump / {print $2}')

                                                    # Utilise uniquement le dernier segment après le dernier /
                                                    local server_name="${ssh_host##*/}"
                                                    local mount_point="/tmp/$server_name"
                                                    mkdir -p "$mount_point"

                                                    # Check si déjà monté
                                                    if mountpoint -q "$mount_point" 2 > /dev/null; then
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
                                                            echo "✗ Failed to mount" > &2
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
                                                              local mounted=$(find /tmp -maxdepth 1 -type d -exec mountpoint -q {} \; -print 2 > /dev/null | xargs -n1 basename)
                                                                if [[ -z "$mounted" ]]; then
                                                                  echo "No mounted servers found in /tmp" > &2
                                                                  return 1
                                                                fi
                                                                server=$(echo "$mounted" | fzf --prompt="Select server to unmount: ")
                                                                  if [[ -z "$server" ]]; then
                                                                    echo "No server selected" > &2
                                                                    return 1
                                                                  fi
                                                                fi

                                                                local mount_point="/tmp/$server"
                                                                if mountpoint -q "$mount_point" 2 > /dev/null; then
                                                                  fusermount -u "$mount_point" 2 > /dev/null || umount "$mount_point"
                                                                  echo "✓ Unmounted $mount_point"
                                                                  else
                                                                    echo "⚠ Not mounted: $mount_point"
                                                                  fi
                                                                }
