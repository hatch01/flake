{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.apps.ccache;
in
{
  options.apps.ccache = {
    enable = lib.mkEnableOption "Activer ccache pour la compilation de gros paquets (kernel, ardour, etc.)";
    overlay = lib.mkOption {
      type = lib.types.unspecified;
      default = final: prev: {
        ccacheWrapper = prev.ccacheWrapper.override {
          extraConfig = ''
            export CCACHE_COMPRESS=1
            export CCACHE_DIR="${config.programs.ccache.cacheDir}"
            export CCACHE_UMASK=007
            export CCACHE_MAXSIZE="50G"
            if [ ! -d "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' does not exist"
              echo "Please create it with:"
              echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
              echo "  sudo chown root:nixbld '$CCACHE_DIR'"
              echo "====="
              exit 1
            fi
            if [ ! -w "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
              echo "Please verify its access permissions"
              echo "====="
              exit 1
            fi
          '';
        };

        # Surcharge de linuxPackagesFor pour que n'importe quel noyau configuré (y compris avec Musnix et temps réel) utilise ccache
        linuxPackagesFor =
          kernel:
          prev.linuxPackagesFor (
            if (kernel ? override) then
              kernel.override {
                stdenv = final.ccacheStdenv;
                buildPackages = final.buildPackages // {
                  stdenv = final.buildPackages.ccacheStdenv;
                };
              }
            else
              kernel
          );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ccache.enable = true;

    systemd.tmpfiles.rules = [
      "d ${config.programs.ccache.cacheDir} 2770 ${config.programs.ccache.owner} ${config.programs.ccache.group} - -"
      "z ${config.programs.ccache.cacheDir} 2770 ${config.programs.ccache.owner} ${config.programs.ccache.group} - -"
    ];

    nixpkgs.overlays = [
      cfg.overlay
    ];

    environment.persistence."/persistent".directories = [ "/var/cache/ccache" ];
  };
}
