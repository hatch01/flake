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
          echo "forge.onyx.ovh ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxZPXngowIs04BAN/nPjjCSkSXs9yVm8qHW9pN23RegJjGb37nRTr1YQpWn3+45J6oUTuYUsbEXFuXvlOPC/lKGluHvSEwQI79z01/34UW/MaSV9Wa1zQFThLf5qO6ruf20a6kbJFrCp/58gHRbmNP2kVDOi2hdPCPoHRCPmYQdFN9J9eKlvyeOFoKW0NIi/qQW3xmGzKfRuur7ot4slSaAg9Vbqw+3eMC0Vvk8l3N9VjUhFWpVf2weSstJS+yC6lVdeQyU7D52uU/YEaOeMhhyBzH/SEA2xrIr4CUoDnqd1OV0DNzDA8Zva4dyxNqssgtvpoHVu6qMNL3K58ZOrwkA0wiPTk+gtCZKqvViISy5YNkwhUdLoCWqEx5wEGrT9smNrrp4wlALBeR0KNiCSDDu9l7NfaM/EJ3WiC7Zg31tlp0hIvUsG2bf9MweBPMhaF22GLGlubcx5fVFd3RcRUnn9tgFATcai46khBPga33dsVSWxsNbd4FXvCzc3qlTI1baOJucJR3MRjMD4DYZn+L+ITXAmyqnK2U3UEooE7hm0yJ3xwnyi4jHiZaVNbqP2xri4GAEaXDU5x83zh3Q7iEHkfEJg1nZnj2yOStIXdlXWskYCV+rtzK0EjnFcZFiEK5XTXLUgyo6nbR2yrOUIcmaeQsKW1CgaStej6pym4eMw==" >> ~/.ssh/known_hosts
          echo "forge.onyx.ovh ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIh2XilINjx9e+QZBI1f+OUiexzzQCupRqt7DvpBDZuu" >> ~/.ssh/known_hosts
          git config --global user.email "root@jonquille.onyx.ovh"
          git config --global user.name "System administrator"

          cd /tmp/
          if [ ! -d "flake/.git" ]; then
              git clone "gitlab@forge.onyx.ovh:eymeric/flake.git" "flake"
          fi

          cd "flake" || exit
          git reset --hard HEAD
          git pull
          nix flake update --commit-lock-file --accept-flake-config
          git push
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
          lib.getExe (pkgs.writeShellScriptBin "route-hander" script)
        }
      '';
    };
  };
}
