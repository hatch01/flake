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

    PROFILES_DIR="/nix/var/nix/profiles"
    COMIN_STATE_DIR="/var/lib/comin"
    LAST_MAILED_GEN_FILE="$COMIN_STATE_DIR/last-mailed-generation"

    GEN_JSON=$(${lib.getExe pkgs.nixos-rebuild} list-generations --json 2>/dev/null || true)

    CURR_GEN=$(echo "$GEN_JSON" \
      | ${lib.getExe pkgs.jq} -r '.[] | select(.current == true) | .generation' \
      | ${lib.getExe' pkgs.coreutils "head"} -n1)

    PREV_GEN=$(echo "$GEN_JSON" \
      | ${lib.getExe pkgs.jq} -r '.[] | select(.current == false) | .generation' \
      | ${lib.getExe' pkgs.coreutils "head"} -n1)

    if [ -n "$CURR_GEN" ] && [ "$CURR_GEN" != "null" ]; then
      CURR_PROFILE="$PROFILES_DIR/system-''${CURR_GEN}-link"
    else
      CURR_PROFILE=""
    fi

    if [ -n "$PREV_GEN" ] && [ "$PREV_GEN" != "null" ]; then
      PREV_PROFILE="$PROFILES_DIR/system-''${PREV_GEN}-link"
    else
      PREV_PROFILE=""
    fi

    LAST_MAILED_GEN=""
    if [ -r "$LAST_MAILED_GEN_FILE" ]; then
      LAST_MAILED_GEN=$(${lib.getExe' pkgs.coreutils "cat"} "$LAST_MAILED_GEN_FILE" 2>/dev/null || true)
    fi

    if [ -z "$CURR_PROFILE" ] || [ ! -e "$CURR_PROFILE" ]; then
      DIFF="(could not determine current generation/profile)"
    elif [ -n "$LAST_MAILED_GEN" ] && [ "$LAST_MAILED_GEN" = "$CURR_GEN" ]; then
      DIFF="(generation unchanged since last notification; skipped diff)"
    elif [ -z "$PREV_PROFILE" ] || [ ! -e "$PREV_PROFILE" ]; then
      DIFF="(no previous generation to diff against)"
    else
      CURR_TARGET=$(${lib.getExe' pkgs.coreutils "readlink"} -f "$CURR_PROFILE" || true)
      PREV_TARGET=$(${lib.getExe' pkgs.coreutils "readlink"} -f "$PREV_PROFILE" || true)

      if [ -n "$CURR_TARGET" ] && [ -n "$PREV_TARGET" ] && [ "$CURR_TARGET" = "$PREV_TARGET" ]; then
        DIFF="(no effective change: current and previous generations point to same system path)"
      else
        DIFF=$(${lib.getExe pkgs.dix} "$PREV_PROFILE" "$CURR_PROFILE" 2>&1 || true)
        [ -n "$DIFF" ] || DIFF="(no diff output)"
      fi
    fi

    if [ -n "$CURR_GEN" ] && [ "$CURR_GEN" != "null" ]; then
      if [ -d "$COMIN_STATE_DIR" ] && [ -w "$COMIN_STATE_DIR" ]; then
        printf '%s\n' "$CURR_GEN" > "$LAST_MAILED_GEN_FILE" || true
      fi
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
