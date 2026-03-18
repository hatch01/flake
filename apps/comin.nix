{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  postDeploymentScript = pkgs.writers.writeBash "comin-post-deploy" ''
    set -euo pipefail

    # Derive current and previous generation numbers from the profile symlinks.
    PROFILES_DIR="/nix/var/nix/profiles"
    CURR_GEN=$(${lib.getExe' pkgs.coreutils "readlink"} "$PROFILES_DIR/system" | ${lib.getExe' pkgs.gnugrep "grep"} -oP 'system-\K[0-9]+(?=-link)' || true)
    CURR_PROFILE="$PROFILES_DIR/system-''${CURR_GEN}-link"

    # Find the previous generation: highest numbered profile below current
    PREV_GEN=$(
      ${lib.getExe' pkgs.coreutils "ls"} -d "$PROFILES_DIR"/system-*-link 2>/dev/null \
        | ${lib.getExe' pkgs.gnugrep "grep"} -oP 'system-\K[0-9]+(?=-link)' \
        | ${lib.getExe' pkgs.coreutils "sort"} -n \
        | ${lib.getExe pkgs.gawk} -v cur="$CURR_GEN" '$1 < cur' \
        | ${lib.getExe' pkgs.coreutils "tail"} -1 \
        || true
    )

    if [ -n "$PREV_GEN" ]; then
      PREV_PROFILE="$PROFILES_DIR/system-''${PREV_GEN}-link"
    else
      PREV_PROFILE=""
    fi

    if [ -n "$PREV_PROFILE" ] && [ -e "$PREV_PROFILE" ]; then
      DIFF=$(${lib.getExe pkgs.dix} "$PREV_PROFILE" "$CURR_PROFILE" 2>&1 || true)
    else
      DIFF="(no previous generation to diff against)"
    fi

    {
      echo "To: root"
      echo "Subject: [comin] ''${COMIN_STATUS:-} deployment on ''${COMIN_HOSTNAME:-} (gen ''${COMIN_GENERATION:-})"
      echo ""
      echo "Deployment details"
      echo "=================="
      echo "Host:       ''${COMIN_HOSTNAME:-}"
      echo "Status:     ''${COMIN_STATUS:-}"
      echo "Generation: ''${COMIN_GENERATION:-}"
      echo "Ref:        ''${COMIN_GIT_REF:-}"
      echo "SHA:        ''${COMIN_GIT_SHA:-}"
      echo "Flake URL:  ''${COMIN_FLAKE_URL:-}"
      echo "Message:    ''${COMIN_GIT_MSG:-}"
      if [ -n "''${COMIN_ERROR_MSG:-}" ]; then
        echo ""
        echo "Error"
        echo "====="
        echo "''${COMIN_ERROR_MSG:-}"
      fi
      echo ""
      echo "Diff (previous -> current generation)"
      echo "=============================="
      echo "$DIFF"
    } | ${lib.getExe config.programs.msmtp.package} -t
  '';
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  options = {
    comin.enable = mkEnableOption "Enable service";
  };

  config = mkIf config.comin.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://${config.forgejo.domain}/eymeric/flake.git";
          branches.main.name = "main";
        }
      ];
      postDeploymentCommand = postDeploymentScript;
    };
  };
}
