#!/usr/bin/env bash
# shellcheck shell=bash
# impure: needs internet


set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"
PATCHES_FILE="$FLAKE_DIR/patches.nix"

NIXPKGS_PATCHED_URL="git+ssh://forgejo@forge.onyx.ovh:443/eymeric/nixpkgs-patched.git"
NIXPKGS_PATCHED_URL_GITHUB_MIRROR="git@github.com:hatch01/nixpkgs-patched.git"
NIXPKGS_FORGE_REPO="git+ssh://forgejo@forge.onyx.ovh:443/github_mirror/nixpkgs.git"
WORK_DIR="/tmp/nixpkgs-patched-update"
NIXPKGS_STABLE_VERSION="nixos-26.05"
NIXPKGS_REPO="NixOS/nixpkgs"

GIT_AUTHOR_NAME="NixPkgs Patcher"
GIT_AUTHOR_EMAIL="patcher@nixpkgs.local"
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# Apply patches to a specific branch
apply_patches() {
	local repo_dir=$1
	local branch=$2
	local patches_json=$3

	cd "$repo_dir"

	git switch "$branch" >/dev/null 2>&1

	local patch_cache_dir="${repo_dir}_cache"
	mkdir -p "$patch_cache_dir"

	local github_auth_header=()
	if [ -n "${GITHUB_TOKEN:-}" ]; then
		github_auth_header=(-H "Authorization: Bearer $GITHUB_TOKEN")
	fi

	# Process each patch (PR numbers or branch names)
	echo "$patches_json" | jq -c '.[]' | while IFS= read -r patch_data; do
		pr_number=$(echo "$patch_data" | jq -r '.pr')
		branch_name=$(echo "$patch_data" | jq -r '.branch')
		patch_name=$(echo "$patch_data" | jq -r '.name')

		if [ "$pr_number" != "null" ]; then
			echo "Attempting to apply PR $patch_data"
			cache_file="$patch_cache_dir/pr_${pr_number}.diff"
			diff_url="https://github.com/$NIXPKGS_REPO/pull/$pr_number.diff"
			echo "Downloading PR #$pr_number diff from: $diff_url"
			fail_msg="Failed to download diff for PR #$pr_number (PR may not exist or is inaccessible)"
			apply_msg="Apply PR #$pr_number: $patch_name"
			success_msg="Diff check passed for PR #$pr_number, applying..."
			err_apply_msg="Failed to apply diff for PR #$pr_number"
			err_conflict_msg="Diff for PR #$pr_number has conflicts or issues"
		elif [ "$branch_name" != "null" ]; then
			branch_owner=$(echo "$patch_data" | jq -r '.owner // "hatch01"')
			base_override=$(echo "$patch_data" | jq -r '.base // empty')
			echo "Attempting to apply branch $patch_data (owner: $branch_owner)"
			cache_file="$patch_cache_dir/branch_${branch_owner}_${branch_name}.diff"

			if [ -n "$base_override" ]; then
				echo "Using explicitly specified base '$base_override' for branch $branch_name"
				diff_url="https://github.com/$NIXPKGS_REPO/compare/${base_override}...${branch_owner}:nixpkgs:${branch_name}.patch"
			else
				# Find where the branch diverged from upstream to only include commits added on this branch
				candidates=("master" "nixos-unstable" "$NIXPKGS_STABLE_VERSION" "staging")
				best_base="master"
				min_ahead=999999999
				merge_base_sha=""

				for candidate in "${candidates[@]}"; do
					api_url="https://api.github.com/repos/$NIXPKGS_REPO/compare/${candidate}...${branch_owner}:${branch_name}"
					compare_json=$(curl -sL "${github_auth_header[@]}" -H "Accept: application/vnd.github.v3+json" "$api_url" 2>/dev/null || true)
					if [ -n "$compare_json" ]; then
						ahead=$(echo "$compare_json" | jq -r '.ahead_by // empty' 2>/dev/null || true)
						mb_sha=$(echo "$compare_json" | jq -r '.merge_base_commit.sha // empty' 2>/dev/null || true)
						if [ -n "$ahead" ] && [ "$ahead" != "null" ] && [ "$ahead" -lt "$min_ahead" ] 2>/dev/null; then
							min_ahead="$ahead"
							best_base="$candidate"
							merge_base_sha="$mb_sha"
						fi
					fi
				done

				if [ -n "$merge_base_sha" ] && [ "$merge_base_sha" != "null" ]; then
					echo "Detected branch base relative to $best_base (merge base: $merge_base_sha, $min_ahead commits ahead)"
					diff_url="https://github.com/$NIXPKGS_REPO/compare/${merge_base_sha}...${branch_owner}:nixpkgs:${branch_name}.patch"
				else
					echo "Falling back to comparing against $best_base for branch $branch_name"
					diff_url="https://github.com/$NIXPKGS_REPO/compare/${best_base}...${branch_owner}:nixpkgs:${branch_name}.patch"
				fi
			fi

			echo "Downloading branch $branch_name patch from: $diff_url"
			fail_msg="Failed to download patch for branch $branch_name (branch may not exist or is inaccessible)"
			apply_msg="Apply branch $branch_name: $patch_name"
			success_msg="Patch check passed for branch $branch_name, applying..."
			err_apply_msg="Failed to apply patch for branch $branch_name"
			err_conflict_msg="Patch for branch $branch_name has conflicts or issues"
		else
			echo "Error: patch data has neither 'pr' nor 'branch' field: $patch_data"
			exit 1
		fi

		if [ -f "$cache_file" ]; then
			diff_output=$(cat "$cache_file")
		else
			diff_output=$(curl -sL -f "$diff_url" 2>/dev/null || true)
			if [ -z "$diff_output" ]; then
				echo "$fail_msg"
				exit 1
			fi
			echo "$diff_output" > "$cache_file"
		fi

		if echo "$diff_output" | git apply --check 2>/dev/null; then
			echo "$success_msg"
			if echo "$diff_output" | git apply 2>/dev/null; then
				git add . >/dev/null 2>&1

				# Use the commit date for both author and committer
				commit_date=$(git log -1 --format=%aI HEAD)
				GIT_AUTHOR_DATE="$commit_date" \
				GIT_COMMITTER_DATE="$commit_date" \
				git commit --no-gpg-sign -m "$apply_msg" --no-edit >/dev/null 2>&1 || true
			else
				echo "$err_apply_msg"
				echo "$diff_output" | git apply || true
				exit 1
			fi
		else
			echo "$err_conflict_msg"
			echo "$diff_output" | git apply --check || true
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
trap 'rm -rf "$WORK_DIR" "${WORK_DIR}_cache"' EXIT

categories=("common" "stable" "unstable")

echo "Updating unstable branch with upstream changes..."
git fetch upstream "nixos-unstable" --depth=1 >/dev/null 2>&1
git switch -c "nixos-unstable" main >/dev/null 2>&1
unstable_date=$(git log -1 --format=%aI "upstream/nixos-unstable")
GIT_AUTHOR_DATE="$unstable_date" \
GIT_COMMITTER_DATE="$unstable_date" \
git cherry-pick --no-gpg-sign "upstream/nixos-unstable" >/dev/null

echo "Updating stable branch with upstream changes..."
git fetch upstream "$NIXPKGS_STABLE_VERSION" --depth=1 >/dev/null 2>&1
git switch -c "nixos-stable" main >/dev/null 2>&1
stable_date=$(git log -1 --format=%aI "upstream/$NIXPKGS_STABLE_VERSION")
GIT_AUTHOR_DATE="$stable_date" \
GIT_COMMITTER_DATE="$stable_date" \
git cherry-pick --no-gpg-sign "upstream/$NIXPKGS_STABLE_VERSION" >/dev/null


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
		apply_patches "$WORK_DIR" "nixos-unstable" "$patches"
		apply_patches "$WORK_DIR" "nixos-stable" "$patches"
		;;
	stable)
		apply_patches "$WORK_DIR" "nixos-stable" "$patches"
		;;
	unstable)
		apply_patches "$WORK_DIR" "nixos-unstable" "$patches"
		;;
	esac
done

# Backup old branches before force pushing
DATE=$(date +%Y%m%d-%H%M%S)

echo "Backing up branches before force push..."
backup_branch="nixos-unstable-${DATE}"
if git fetch origin "nixos-unstable" >/dev/null 2>&1; then
	git push origin "FETCH_HEAD:refs/heads/$backup_branch" >/dev/null 2>&1 && echo "Backed up nixos-unstable as $backup_branch to origin" || echo "Failed to backup to origin"
	git push mirror "FETCH_HEAD:refs/heads/$backup_branch" >/dev/null 2>&1 && echo "Backed up nixos-unstable as $backup_branch to mirror" || echo "Failed to backup to mirror"
else
	echo "Branch nixos-unstable does not exist yet on origin, skipping backup"
fi
backup_branch="nixos-stable-${DATE}"
if git fetch origin "nixos-stable" >/dev/null 2>&1; then
	git push origin "FETCH_HEAD:refs/heads/$backup_branch" >/dev/null 2>&1 && echo "Backed up nixos-stable as $backup_branch to origin" || echo "Failed to backup to origin"
	git push mirror "FETCH_HEAD:refs/heads/$backup_branch" >/dev/null 2>&1 && echo "Backed up nixos-stable as $backup_branch to mirror" || echo "Failed to backup to mirror"
else
	echo "Branch nixos-stable does not exist yet on origin, skipping backup"
fi

# Now force push the new patched branches
echo "Force pushing updates ..."
git push --force origin "nixos-unstable:nixos-unstable" >/dev/null 2>&1 && echo "Pushed updates to origin/nixos-unstable"
git push --force mirror "nixos-unstable:nixos-unstable" >/dev/null 2>&1 && echo "Pushed updates to mirror/nixos-unstable"
git push --force origin "nixos-stable:nixos-stable" >/dev/null 2>&1 && echo "Pushed updates to origin/nixos-stable"
git push --force mirror "nixos-stable:nixos-stable" >/dev/null 2>&1 && echo "Pushed updates to mirror/nixos-stable"

echo "Patches update completed successfully"
