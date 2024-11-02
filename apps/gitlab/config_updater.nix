{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options = {
    gitlab = {
      configUpdater = {
        enable = mkEnableOption "enable Gitlab";
        port = mkOption {
          type = types.int;
          default = 8084;
          description = "The port to listen on";
        };
      };
    };
  };

  config = mkIf config.gitlab.configUpdater.enable {
    systemd.services.config-updater = {
      enable = true;
      path = with pkgs; [
        git
        openssh
        gawk
        socat
        nix
      ];
      description = "HTTP server using socat for Git update actions";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "always";
      };
      script = ''
        socat TCP4-LISTEN:${builtins.toString config.gitlab.configUpdater.port},reuseaddr,fork SYSTEM:${
          lib.getExe (pkgs.writeShellScriptBin "route-hander" ''
            read request
            path=$(echo "$request" | awk '{print $2}')

            case "$path" in
              /update)
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nUpdating repository..."
                # Commandes pour l'action "update"
                # Clone if the repository doesn't exist
                ssh-keyscan forge.onyx.ovh >> ~/.ssh/known_hosts
                cd /tmp/
                if [ ! -d "flake/.git" ]; then
                    git clone "gitlab@forge.onyx.ovh:eymeric/flake.git" "flake"
                fi

                cd "flake" || exit
                git reset --hard HEAD
                git pull
                nix flake update --commit-lock-file --accept-flake-config
                git push

                ;;
              *)
                # Réponse par défaut pour les chemins inconnus
                echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nPath not found"
                ;;
            esac
          '')
        }
      '';
    };
  };
}
