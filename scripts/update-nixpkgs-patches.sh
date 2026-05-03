#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"
PATCHES_FILE="$FLAKE_DIR/patches.nix"

NIXPKGS_PATCHED_URL="git+ssh://forgejo@forge.onyx.ovh:443/eymeric/nixpkgs-patched.git"
NIXPKGS_PATCHED_URL_GITHUB_MIRROR="git@github.com:hatch01/nixpkgs-patched.git"
NIXPKGS_FORGE_REPO="git+ssh://forgejo@forge.onyx.ovh:443/github_mirror/nixpkgs.git"
WORK_DIR="/tmp/nixpkgs-patched-update"
NIXPKGS_STABLE_VERSION="nixos-25.11"
NIXPKGS_REPO="NixOS/nixpkgs"

# Apply patches to a specific branch
apply_patches() {
	local repo_dir=$1
	local branch=$2
	local patches_json=$3

	cd "$repo_dir"

	git switch "$branch" >/dev/null 2>&1

	# Process each patch (now just PR numbers)
	echo "$patches_json" | jq -c '.[]' | while IFS= read -r pr_data; do
		echo "Attempting to apply PR $pr_data"

		pr_number=$(echo "$pr_data" | jq -r '.pr')
		pr_name=$(echo "$pr_data" | jq -r '.name')

		diff_url="https://github.com/$NIXPKGS_REPO/pull/$pr_number.diff"
		echo "Downloading PR #$pr_number diff from: $diff_url"

		diff_output=$(curl -sL -f "$diff_url" 2>/dev/null)
		if [ -z "$diff_output" ]; then
			echo "Failed to download diff for PR #$pr_number (PR may not exist or is inaccessible)"
			exit 1
		fi

		if echo "$diff_output" | git apply --check 2>/dev/null 2>&1; then
			echo "Diff check passed for PR #$pr_number, applying..."
			if echo "$diff_output" | git apply 2>/dev/null 2>&1; then
				git add . >/dev/null 2>&1
				git commit -m "Apply PR #$pr_number: $pr_name" --no-edit >/dev/null 2>&1 || true
			else
				echo "Failed to apply diff for PR #$pr_number"
				exit 1
			fi
		else
			echo "Diff for PR #$pr_number has conflicts or issues"
			exit 1
		fi
	done
}

echo "Initializing work directory: $WORK_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

git clone --single-branch -b main "$NIXPKGS_PATCHED_URL" "$WORK_DIR" >/dev/null 2>&1
echo "Cloned repository to $WORK_DIR"
cd "$WORK_DIR"

git remote add upstream "$NIXPKGS_FORGE_REPO" >/dev/null
git remote add mirror "$NIXPKGS_PATCHED_URL_GITHUB_MIRROR" >/dev/null

# Cleanup on exit
trap "rm -rf $WORK_DIR" EXIT

branches=("nixos-unstable" "$NIXPKGS_STABLE_VERSION")
categories=("common" "stable" "unstable")

for branch in "${branches[@]}"; do
	echo "Updating branch '$branch' with upstream changes..."
	git fetch upstream "$branch" --depth=1 >/dev/null 2>&1
	git switch -c "$branch" main >/dev/null 2>&1
	git cherry-pick "upstream/$branch" >/dev/null
done

for category in "${categories[@]}"; do
	echo "Processing '$category' patches..."

	patches=$(nix eval --impure --json --expr "(import $PATCHES_FILE).$category")
	echo "Retrieved patches for '$category': $patches"

	if [ "$patches" = "[]" ]; then
		echo "No patches in '$category' category"
		continue
	fi

	case "$category" in
	common)
		for branch in "${branches[@]}"; do
			apply_patches "$WORK_DIR" "$branch" "$patches"
		done
		;;
	stable)
		apply_patches "$WORK_DIR" "$NIXPKGS_STABLE_VERSION" "$patches"
		;;
	unstable)
		apply_patches "$WORK_DIR" "nixos-unstable" "$patches"
		;;
	esac
done

for branch in "${branches[@]}"; do
	git push --force origin "$branch:$branch" >/dev/null 2>&1 && git push --force mirror "$branch:$branch" >/dev/null 2>&1
	echo "Pushed updates to $branch"
done

echo "Patches update completed successfully"
