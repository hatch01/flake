#!/usr/bin/env bash
#
# brm - Delete a file or folder from the live btrfs filesystem AND from
#        every btrfs subvolume/snapshot where the same relative path exists.
#
# Usage:
#   sudo brm [-n|--dry-run] [-y|--yes] <path>
#
#   <path> may be relative (resolved against $PWD) or absolute.
#
# IMPORTANT ASSUMPTION:
#   The detected btrfs mountpoint must be mounted such that ALL
#   subvolumes/snapshots are visible underneath it as normal directories.
#   In practice this means it should be mounted as (or descend from) the
#   top-level subvolume (subvolid=5).

set -uo pipefail

SCRIPT_NAME=$(basename "$0")
DRY_RUN=0
ASSUME_YES=0

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [-n|--dry-run] [-y|--yes] <path>

  -n, --dry-run   Show what would be deleted, delete nothing.
  -y, --yes       Don't ask for confirmation before deleting.
  -h, --help      Show this help.
EOF
    exit 1
}

die() { echo "Error: $*" >&2; exit 1; }

# --- argument parsing ---
ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) usage ;;
        --) shift; while [ $# -gt 0 ]; do ARGS+=("$1"); shift; done ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) ARGS+=("$1") ;;
    esac
    shift
done

[ "${#ARGS[@]}" -eq 1 ] || usage
Input="${ARGS[0]}"

if [ "$DRY_RUN" -eq 0 ] && [ "$(id -u)" -ne 0 ]; then
    die "Must run as root (needed to flip btrfs read-only properties and delete inside snapshots). Try: sudo $SCRIPT_NAME $*"
fi

command -v btrfs   >/dev/null 2>&1 || die "'btrfs' command not found."
command -v findmnt >/dev/null 2>&1 || die "'findmnt' command not found."

# --- resolve input to an absolute path, independent of current pwd ---
AbsInput=$(realpath -m -- "$Input") || die "Could not resolve path: $Input"
ParentDir=$(dirname -- "$AbsInput")
[ -e "$ParentDir" ] || die "Parent directory does not exist: $ParentDir"

LiveExists=0
[ -e "$AbsInput" ] && LiveExists=1

# --- find the btrfs mountpoint that owns this path ---
FsType=$(findmnt -no FSTYPE --target "$ParentDir") || die "Could not stat filesystem for $ParentDir"
[ "$FsType" = "btrfs" ] || die "$AbsInput is not on a btrfs filesystem (detected: $FsType)."

PathToVolume=$(findmnt -no TARGET --target "$ParentDir") || die "Could not determine btrfs mountpoint for $ParentDir"
PathToVolume="${PathToVolume%/}/"   # normalize to exactly one trailing slash

# Path of the target relative to that mountpoint (no leading slash)
RelInputPath="${AbsInput#"${PathToVolume%/}"}"
RelInputPath="${RelInputPath#/}"

echo "Target:             $AbsInput"
echo "Btrfs mountpoint:   $PathToVolume"
echo "Relative path:      $RelInputPath"
if [ "$LiveExists" -eq 1 ]; then
    echo "Exists on live fs:  yes"
else
    echo "Exists on live fs:  no (will still search snapshots)"
fi
echo

# --- gather subvolumes visible under this mountpoint ---
SubvolListRaw=$(btrfs subvolume list "$PathToVolume" 2>&1) || die "btrfs subvolume list failed: $SubvolListRaw"

# Grab everything after the literal " path " marker, so subvolume paths
# containing spaces are still handled correctly.
mapfile -t Subvolumes < <(printf '%s\n' "$SubvolListRaw" | sed -n 's/^.* path //p')

[ "${#Subvolumes[@]}" -eq 0 ] && echo "No subvolumes found under $PathToVolume (only the live filesystem will be affected)."

# --- work out what actually needs deleting ---
declare -a TargetsToDelete=()
[ "$LiveExists" -eq 1 ] && TargetsToDelete+=("$AbsInput")

declare -a SnapshotHits=()
for Subvol in "${Subvolumes[@]}"; do
    Candidate="${PathToVolume}${Subvol}/${RelInputPath}"
    if [ -e "$Candidate" ]; then
        SnapshotHits+=("$Subvol")
        TargetsToDelete+=("$Candidate")
    fi
done

echo "Found in ${#SnapshotHits[@]} subvolume(s):"
for s in "${SnapshotHits[@]}"; do echo "  - $s"; done
echo

if [ "${#TargetsToDelete[@]}" -eq 0 ]; then
    echo "Nothing to delete (path not found live or in any subvolume)."
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry run] Would delete:"
    for t in "${TargetsToDelete[@]}"; do echo "  rm -rf -- '$t'"; done
    exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
    echo "About to permanently delete ${#TargetsToDelete[@]} path(s), including inside btrfs snapshots."
      read -r -p "Type 'yes (y)' to continue: " confirm
    [[ "$confirm" == "yes" || "$confirm" == "y" ]] || { echo "Aborted."; exit 1; }
fi

DeleteFileOrFolder() {
    echo "Deleting ... $1"
    if rm -rf -- "$1"; then
        echo "Deleted successfully."
    else
        echo "Failed to delete: $1" >&2
    fi
}

# 1. live filesystem
[ "$LiveExists" -eq 1 ] && DeleteFileOrFolder "$AbsInput"

# 2. every subvolume that had a hit
for Subvol in "${SnapshotHits[@]}"; do
    SnapshotPath="${PathToVolume}${Subvol}"
    Candidate="${SnapshotPath}/${RelInputPath}"
    echo "--- $SnapshotPath ---"

    RoInfo=$(btrfs property get "$SnapshotPath" ro 2>/dev/null)
    IsRo="${RoInfo##*=}"

    if [ "$IsRo" = "true" ]; then
        if btrfs property set "$SnapshotPath" ro false; then
            echo "Set subvolume to read-write."
        else
            echo "Could not set subvolume read-write, skipping." >&2
            printf '\n'
            continue
        fi

        DeleteFileOrFolder "$Candidate"

        if btrfs property set "$SnapshotPath" ro true; then
            echo "Restored subvolume to read-only."
        else
            echo "WARNING: failed to restore read-only status on $SnapshotPath" >&2
        fi
    else
        DeleteFileOrFolder "$Candidate"
    fi
    printf '\n'
done

echo "Done."
