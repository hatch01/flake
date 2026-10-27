#!/usr/bin/env python3
import datetime
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FLAKE_DIR = os.path.dirname(SCRIPT_DIR)
PATCHES_FILE = os.path.join(FLAKE_DIR, "patches.nix")

NIXPKGS_PATCHED_URL = "git+ssh://forgejo@forge.onyx.ovh:443/eymeric/nixpkgs-patched.git"
NIXPKGS_PATCHED_URL_GITHUB_MIRROR = "git@github.com:hatch01/nixpkgs-patched.git"
NIXPKGS_FORGE_REPO = "git+ssh://forgejo@forge.onyx.ovh:443/github_mirror/nixpkgs.git"
WORK_DIR = "/tmp/nixpkgs-patched-update"
NIXPKGS_STABLE_VERSION = "nixos-26.05"
NIXPKGS_REPO = "NixOS/nixpkgs"

os.environ["GIT_AUTHOR_NAME"] = "NixPkgs Patcher"
os.environ["GIT_AUTHOR_EMAIL"] = "patcher@nixpkgs.local"
os.environ["GIT_COMMITTER_NAME"] = os.environ["GIT_AUTHOR_NAME"]
os.environ["GIT_COMMITTER_EMAIL"] = os.environ["GIT_AUTHOR_EMAIL"]

def run(cmd, cwd=None, check=True, capture=False, env=None):
    if env is None:
        env = os.environ.copy()
    return subprocess.run(cmd, cwd=cwd, check=check, text=True, capture_output=capture, shell=isinstance(cmd, str), env=env)

def api_req(url):
    req = urllib.request.Request(url)
    token = os.environ.get('GITHUB_TOKEN')
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        print(f"HTTP Error fetching {url}: {e.code}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return None

def is_commit_in_branch(sha, branch):
    res = api_req(f"https://api.github.com/repos/{NIXPKGS_REPO}/compare/{branch}...{sha}")
    if res:
        return res.get("status") in ["identical", "behind"]
    return False

def check_pr_merged_branches(pr_number, stable_branch):
    pr = api_req(f"https://api.github.com/repos/{NIXPKGS_REPO}/pulls/{pr_number}")
    if not pr or not pr.get("merged") or not pr.get("merge_commit_sha"):
        return False, False
    sha = pr["merge_commit_sha"]
    in_unstable = is_commit_in_branch(sha, "nixos-unstable")
    in_stable = is_commit_in_branch(sha, stable_branch)
    return in_unstable, in_stable

def get_nix_patches():
    res = run(["nix", "eval", "--impure", "--json", "-f", PATCHES_FILE], capture=True)
    return json.loads(res.stdout)

def write_nix_patches(data):
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        json.dump(data, f)
        temp_json = f.name
    
    nix_expr = f'''
let
  lib = (import <nixpkgs> {{}}).lib;
  data = builtins.fromJSON (builtins.readFile "{temp_json}");
in lib.generators.toPretty {{}} data
'''
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        f.write(nix_expr)
        temp_nix = f.name
        
    try:
        res = run(["nix", "eval", "--impure", "--raw", "-f", temp_nix], capture=True)
        with open(PATCHES_FILE, "w") as f:
            f.write(res.stdout)
        run(["nix", "fmt", PATCHES_FILE], capture=True, check=False)
    finally:
        os.unlink(temp_json)
        os.unlink(temp_nix)

def apply_patches(repo_dir, branch, patches_list):
    run(["git", "switch", branch], cwd=repo_dir, capture=True)
    patch_cache_dir = f"{repo_dir}_cache"
    os.makedirs(patch_cache_dir, exist_ok=True)
    
    for patch_data in patches_list:
        pr_number = patch_data.get("pr")
        branch_name = patch_data.get("branch")
        patch_name = patch_data.get("name")
        
        diff_url = None
        apply_msg = None
        cache_file = None
        fail_msg = None
        
        if branch_name:
            branch_owner = patch_data.get("owner", "hatch01")
            base_override = patch_data.get("base")
            print(f"Attempting to apply branch {patch_name} (owner: {branch_owner})")
            cache_file = os.path.join(patch_cache_dir, f"branch_{branch_owner}_{branch_name}.diff")
            
            if base_override:
                print(f"Using explicitly specified base '{base_override}' for branch {branch_name}")
                diff_url = f"https://github.com/{NIXPKGS_REPO}/compare/{base_override}...{branch_owner}:nixpkgs:{branch_name}.patch"
            else:
                candidates = ["master", "nixos-unstable", NIXPKGS_STABLE_VERSION, "staging"]
                best_base = "master"
                min_ahead = 999999999
                merge_base_sha = None
                
                for candidate in candidates:
                    compare_json = api_req(f"https://api.github.com/repos/{NIXPKGS_REPO}/compare/{candidate}...{branch_owner}:{branch_name}")
                    if compare_json:
                        ahead = compare_json.get("ahead_by")
                        mb_sha = compare_json.get("merge_base_commit", {}).get("sha")
                        if ahead is not None and ahead < min_ahead:
                            min_ahead = ahead
                            best_base = candidate
                            merge_base_sha = mb_sha
                
                if merge_base_sha:
                    print(f"Detected branch base relative to {best_base} (merge base: {merge_base_sha}, {min_ahead} commits ahead)")
                    diff_url = f"https://github.com/{NIXPKGS_REPO}/compare/{merge_base_sha}...{branch_owner}:nixpkgs:{branch_name}.patch"
                else:
                    print(f"Falling back to comparing against {best_base} for branch {branch_name}")
                    diff_url = f"https://github.com/{NIXPKGS_REPO}/compare/{best_base}...{branch_owner}:nixpkgs:{branch_name}.patch"
            
            print(f"Downloading branch {branch_name} patch from: {diff_url}")
            fail_msg = f"Failed to download patch for branch {branch_name} (branch may not exist or is inaccessible)"
            apply_msg = f"Apply branch {branch_name}: {patch_name}"
            
        elif pr_number:
            print(f"Attempting to apply PR {pr_number}: {patch_name}")
            cache_file = os.path.join(patch_cache_dir, f"pr_{pr_number}.diff")
            diff_url = f"https://github.com/{NIXPKGS_REPO}/pull/{pr_number}.diff"
            print(f"Downloading PR #{pr_number} diff from: {diff_url}")
            fail_msg = f"Failed to download diff for PR #{pr_number} (PR may not exist or is inaccessible)"
            apply_msg = f"Apply PR #{pr_number}: {patch_name}"
        else:
            print(f"Error: patch data has neither 'pr' nor 'branch' field: {patch_data}", file=sys.stderr)
            sys.exit(1)
            
        # Download diff if not cached
        diff_output = ""
        if os.path.exists(cache_file):
            with open(cache_file, "r") as f:
                diff_output = f.read()
        else:
            req = urllib.request.Request(diff_url)
            try:
                with urllib.request.urlopen(req) as response:
                    diff_output = response.read().decode()
                    with open(cache_file, "w") as f:
                        f.write(diff_output)
            except Exception as e:
                print(f"{fail_msg}\n{e}", file=sys.stderr)
                sys.exit(1)
        
        # Apply patch
        try:
            run(["git", "apply", "--check"], cwd=repo_dir, input=diff_output, capture=True)
            print(f"Patch check passed for {apply_msg}, applying...")
            run(["git", "apply"], cwd=repo_dir, input=diff_output, capture=True)
            run(["git", "add", "."], cwd=repo_dir, capture=True)
            
            commit_date = run(["git", "log", "-1", "--format=%aI", "HEAD"], cwd=repo_dir, capture=True).stdout.strip()
            env = os.environ.copy()
            env["GIT_AUTHOR_DATE"] = commit_date
            env["GIT_COMMITTER_DATE"] = commit_date
            run(["git", "commit", "--no-gpg-sign", "-m", apply_msg, "--no-edit"], cwd=repo_dir, capture=True, check=False, env=env)
            
        except subprocess.CalledProcessError:
            print(f"Failed to apply patch for {apply_msg}. Conflicts or issues exist.", file=sys.stderr)
            try:
                run(["git", "apply"], cwd=repo_dir, input=diff_output, capture=True)
            except subprocess.CalledProcessError:
                pass
            sys.exit(1)

def cleanup():
    if os.path.exists(WORK_DIR):
        shutil.rmtree(WORK_DIR)
    if os.path.exists(f"{WORK_DIR}_cache"):
        shutil.rmtree(f"{WORK_DIR}_cache")

def main():
    commit_changes = "--commit" in sys.argv
    if commit_changes:
        sys.argv.remove("--commit")
        
    cleanup()
    print("Checking and updating patches.nix for merged PRs...")
    data = get_nix_patches()
    new_data = {"stable": [], "unstable": [], "common": []}
    changes_made = []
    
    for category in ["stable", "unstable", "common"]:
        for patch in data.get(category, []):
            pr = patch.get("pr")
            if not pr:
                new_data[category].append(patch)
                continue
                
            in_unstable, in_stable = check_pr_merged_branches(pr, NIXPKGS_STABLE_VERSION)
            
            if category == "unstable":
                if in_unstable:
                    print(f"PR {pr} is merged in unstable. Removing.")
                    changes_made.append(f"Remove #{pr} (merged in unstable)")
                else:
                    new_data["unstable"].append(patch)
            elif category == "stable":
                if in_stable:
                    print(f"PR {pr} is merged in stable. Removing.")
                    changes_made.append(f"Remove #{pr} (merged in stable)")
                else:
                    new_data["stable"].append(patch)
            elif category == "common":
                if in_unstable and in_stable:
                    print(f"PR {pr} is merged in BOTH stable and unstable. Removing.")
                    changes_made.append(f"Remove #{pr} (merged in both)")
                elif in_unstable and not in_stable:
                    print(f"PR {pr} is merged in unstable ONLY. Moving to stable.")
                    changes_made.append(f"Move #{pr} to stable")
                    new_data["stable"].append(patch)
                elif in_stable and not in_unstable:
                    print(f"PR {pr} is merged in stable ONLY. Moving to unstable.")
                    changes_made.append(f"Move #{pr} to unstable")
                    new_data["unstable"].append(patch)
                else:
                    new_data["common"].append(patch)
                    
    write_nix_patches(new_data)
    
    if commit_changes:
        diff_res = run(["git", "diff", "--quiet", PATCHES_FILE], cwd=FLAKE_DIR, check=False)
        if diff_res.returncode != 0:
            commit_msg = "chore(patches): auto-clean merged PRs\n\n"
            if changes_made:
                commit_msg += "\n".join(f"- {c}" for c in changes_made)
            else:
                commit_msg += "Formatted or updated patches.nix"
            run(["git", "add", "patches.nix"], cwd=FLAKE_DIR)
            env_flake = os.environ.copy()
            for k in ["GIT_AUTHOR_NAME", "GIT_AUTHOR_EMAIL", "GIT_COMMITTER_NAME", "GIT_COMMITTER_EMAIL"]:
                env_flake.pop(k, None)
            run(["git", "commit", "-m", commit_msg], cwd=FLAKE_DIR, env=env_flake)
            print("Committed patches.nix modifications.")
    
    if os.environ.get("NO_GIT") == "1":
        print("NO_GIT is set, skipping git clone and patch application.")
        cleanup()
        return
        
    print(f"Initializing work directory: {WORK_DIR}")
    os.makedirs(WORK_DIR, exist_ok=True)
    run(["git", "clone", "--single-branch", "-b", "main", NIXPKGS_PATCHED_URL, WORK_DIR], capture=True)
    print(f"Cloned repository to {WORK_DIR}")
    
    run(["git", "remote", "add", "upstream", NIXPKGS_FORGE_REPO], cwd=WORK_DIR, capture=True)
    run(["git", "remote", "add", "mirror", NIXPKGS_PATCHED_URL_GITHUB_MIRROR], cwd=WORK_DIR, capture=True)
    
    print("Updating unstable branch with upstream changes...")
    run(["git", "fetch", "upstream", "nixos-unstable", "--depth=1"], cwd=WORK_DIR, capture=True)
    run(["git", "switch", "-c", "nixos-unstable", "main"], cwd=WORK_DIR, capture=True)
    unstable_date = run(["git", "log", "-1", "--format=%aI", "upstream/nixos-unstable"], cwd=WORK_DIR, capture=True).stdout.strip()
    env = os.environ.copy()
    env["GIT_AUTHOR_DATE"] = unstable_date
    env["GIT_COMMITTER_DATE"] = unstable_date
    run(["git", "cherry-pick", "--no-gpg-sign", "upstream/nixos-unstable"], cwd=WORK_DIR, capture=True, env=env)
    
    print("Updating stable branch with upstream changes...")
    run(["git", "fetch", "upstream", NIXPKGS_STABLE_VERSION, "--depth=1"], cwd=WORK_DIR, capture=True)
    run(["git", "switch", "-c", "nixos-stable", "main"], cwd=WORK_DIR, capture=True)
    stable_date = run(["git", "log", "-1", "--format=%aI", f"upstream/{NIXPKGS_STABLE_VERSION}"], cwd=WORK_DIR, capture=True).stdout.strip()
    env["GIT_AUTHOR_DATE"] = stable_date
    env["GIT_COMMITTER_DATE"] = stable_date
    run(["git", "cherry-pick", "--no-gpg-sign", f"upstream/{NIXPKGS_STABLE_VERSION}"], cwd=WORK_DIR, capture=True, env=env)
    
    for category in ["common", "stable", "unstable"]:
        print(f"Processing '{category}' patches...")
        patches = new_data.get(category, [])
        if not patches:
            print(f"No patches in '{category}' category")
            continue
            
        if category == "common":
            apply_patches(WORK_DIR, "nixos-unstable", patches)
            apply_patches(WORK_DIR, "nixos-stable", patches)
        elif category == "stable":
            apply_patches(WORK_DIR, "nixos-stable", patches)
        elif category == "unstable":
            apply_patches(WORK_DIR, "nixos-unstable", patches)
            
    date_str = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    print("Backing up branches before force push...")
    
    for br in ["nixos-unstable", "nixos-stable"]:
        backup_br = f"{br}-{date_str}"
        if run(["git", "fetch", "origin", br], cwd=WORK_DIR, capture=True, check=False).returncode == 0:
            if run(["git", "push", "origin", f"FETCH_HEAD:refs/heads/{backup_br}"], cwd=WORK_DIR, capture=True, check=False).returncode == 0:
                print(f"Backed up {br} as {backup_br} to origin")
            else:
                print("Failed to backup to origin")
                
            if run(["git", "push", "mirror", f"FETCH_HEAD:refs/heads/{backup_br}"], cwd=WORK_DIR, capture=True, check=False).returncode == 0:
                print(f"Backed up {br} as {backup_br} to mirror")
            else:
                print("Failed to backup to mirror")
        else:
            print(f"Branch {br} does not exist yet on origin, skipping backup")
            
    print("Force pushing updates ...")
    run(["git", "push", "--force", "origin", "nixos-unstable:nixos-unstable"], cwd=WORK_DIR, capture=True, check=False)
    print("Pushed updates to origin/nixos-unstable")
    run(["git", "push", "--force", "mirror", "nixos-unstable:nixos-unstable"], cwd=WORK_DIR, capture=True, check=False)
    print("Pushed updates to mirror/nixos-unstable")
    
    run(["git", "push", "--force", "origin", "nixos-stable:nixos-stable"], cwd=WORK_DIR, capture=True, check=False)
    print("Pushed updates to origin/nixos-stable")
    run(["git", "push", "--force", "mirror", "nixos-stable:nixos-stable"], cwd=WORK_DIR, capture=True, check=False)
    print("Pushed updates to mirror/nixos-stable")

    print("Patches update completed successfully")
    cleanup()

if __name__ == "__main__":
    try:
        main()
    except BaseException:
        cleanup()
        raise
