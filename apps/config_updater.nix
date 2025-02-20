{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  script = ''
    read request
    path=$(echo "$request" | awk '{print $2}' | cut -d'?' -f1)

    case "$path" in
      /update)
        # Send immediate response to avoid timeout
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nUpdating repository..."

        # Run the update process in the background
        (

          # Setup git and ssh
          export HOME="/root"
          echo "forge.onyx.ovh ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlIfuBShLh2fltsZCHc4nQ4mEsYLM2ZQ8mf+b99P30v" >> ~/.ssh/known_hosts
          echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" >> ~/.ssh/known_hosts
          git config --global user.email "root@jonquille.onyx.ovh"
          git config --global user.name "System administrator"

          cd /tmp/
          if [ ! -d "flake/.git" ]; then
              git clone "forgejo@forge.onyx.ovh:eymeric/flake.git" "flake"
          fi

          cd "flake" || exit
          git reset --hard HEAD
          git pull
          nix flake update --commit-lock-file --accept-flake-config

          # Rebuild systems
          names=$(nix eval --json .#nixosConfigurations --apply 'builtins.attrNames' --accept-flake-config)
          configs=$(echo "$names" | ${lib.getExe pkgs.jq} -- -r '.[]')
          all_ok=true
          for config in $configs; do
            if nix build --accept-flake-config -L --fallback --option trusted-users $(whoami) .#nixosConfigurations.''${config}.config.system.build.toplevel; then
              echo "Build succeeded for ''${config}"
            else
              echo "Build failed for ''${config}, cleaning up..."
              all_ok=false
              break
            fi
          done

          if [ "$all_ok" = true ]; then
            git push
          else
            echo "Not all builds were successful, not pushing changes."
            git reset --hard HEAD~1
          fi
        ) &  # Run in the background
        ;;
      *)
        # Default response for unknown paths
        echo -e "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nPath not found"
        ;;
    esac
  '';
in {
  options = {
    configUpdater = {
      enable = mkEnableOption "enable config updater";
      port = mkOption {
        type = types.int;
        default = 8084;
        description = "The port to listen on";
      };
    };
  };

  config = mkIf config.configUpdater.enable {
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
        socat TCP4-LISTEN:${builtins.toString config.configUpdater.port},reuseaddr,fork SYSTEM:${
          lib.getExe (pkgs.writeShellScriptBin "route-hander" script)
        }
      '';
    };
  };
}
