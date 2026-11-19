# Private recipe to list all nixos configurations
_list_servers:
    @nix --extra-experimental-features "nix-command flakes" eval --json .#nixosConfigurations --apply 'builtins.attrNames' --accept-flake-config | nix run nixpkgs#jq -- -r '.[]'

build machine +args="":
    nix run nixpkgs#nix-fast-build -- --flake .#nixosConfigurations.{{ machine }}.config.system.build.toplevel --systems "x86_64-linux aarch64-linux" --option accept-flake-config true --skip-cached {{ args }}

buildall +args="":
    nix run nixpkgs#nix-fast-build -- --systems "x86_64-linux aarch64-linux" --option accept-flake-config true --skip-cached {{ args }}

rebuild:
    # using impure to allow passing the env vars to nixos-rebuild
    NIXOS_LABEL=$(echo "$(git log -1 --pretty=format:%s)---$(git diff --name-only HEAD)" | paste -sd '-' | tr "/" "_" | tr " " "_" | sed 's/[^a-zA-Z0-9:_\.-]//g') nixos-rebuild switch --flake . --impure --sudo

debug:
    # using impure to allow passing the env vars to nixos-rebuild
    NIXOS_LABEL=$(echo "$(git log -1 --pretty=format:%s)---$(git diff --name-only HEAD)" | paste -sd '-' | tr "/" "_" | tr " " "_" | sed 's/[^a-zA-Z0-9:_\.-]//g') nixos-rebuild switch --flake . --sudo --show-trace --verbose

update:
    just update-patches
    just update-input

update-input +inputs="":
    nix flake update --commit-lock-file --accept-flake-config {{ inputs }}

update-patches +args="":
    nix shell nixpkgs#git nixpkgs#python3 --command python3 ./scripts/update-nixpkgs-patches.py update --commit {{ args }}

add-patch +args="":
    nix shell nixpkgs#git nixpkgs#python3 --command python3 ./scripts/update-nixpkgs-patches.py add {{ args }}

history:
    nix profile history --profile /nix/var/nix/profiles/system

gc:
    # remove all generations older than 7 days
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

    # garbage collect all unused nix store entries
    sudo nix store gc --debug

format machine:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko systems/{{ machine }}/disk.nix

mount machine:
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount systems/{{ machine }}/disk.nix

install machine:
    sudo nixos-install --flake .#{{ machine }}

analyze:
    find -name "*.nix" | xargs -I{} nil diagnostics {}

forecast machine:
    #!/usr/bin/env bash
    substituters=$(nix eval --impure --raw --expr 'let flake = import ./flake.nix; caches = flake.nixConfig.substituters; in builtins.concatStringsSep " " (map (c: "-b " + c) caches)')
    nix-forecast -s -c ".#nixosConfigurations.{{ machine }}" $substituters

sd machine:
    nix run nixpkgs#nixos-generators -- -f sd-aarch64 --flake .#{{ machine }} --system aarch64-linux -o ./{{ machine }}-sd-aarch64
    echo image in ./{{ machine }}-sd-aarch64/sd-image/

remote-install machine ip:
    nix run --extra-experimental-features 'nix-command flakes' github:nix-community/nixos-anywhere -- --flake .#{{ machine }} --target-host root@{{ ip }}

deploy machine="" ip="":
    #!/usr/bin/env bash
    if [ -z "{{ machine }}" ]; then
        echo "No machine specified, deploying to all configurations..."
        for config in $(just _list_servers); do
            echo "Deploying to $config..."
            nixos-rebuild switch --flake .#${config} --target-host root@${config} || echo "Failed to deploy to $config"
        done
    else
        target_ip="{{ ip }}"
        if [ -z "$target_ip" ]; then
            target_ip="{{ machine }}"
        fi
        nixos-rebuild switch --flake .#{{ machine }} --target-host root@${target_ip}
    fi

reset_comin:
    #!/usr/bin/env bash
    echo "Resetting comin on all servers..."
    for config in $(just _list_servers); do
        echo "Resetting comin on $config..."
        ssh root@${config} "rm -rf /var/lib/comin && systemctl restart comin" || echo "Failed to reset comin on $config"
    done

# Generate SBOM for a specific machine (CycloneDX, SPDX, CSV)
sbom machine +args="":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p sboms/{{ machine }}
    echo "Generating SBOM for {{ machine }}..."
    nix shell nixpkgs#sbomnix --command sbomnix \
        .#nixosConfigurations.{{ machine }}.config.system.build.toplevel \
        --cdx sboms/{{ machine }}/sbom.cdx.json \
        --spdx sboms/{{ machine }}/sbom.spdx.json \
        --csv sboms/{{ machine }}/sbom.csv \
        {{ args }}
    echo "SBOMs saved in sboms/{{ machine }}/"

# Generate SBOMs for all servers and systems
sbom-all +args="":
    #!/usr/bin/env bash
    set -euo pipefail
    for machine in $(just _list_servers); do
        echo "=== Generating SBOM for $machine ==="
        just sbom "$machine" {{ args }}
    done

# Scan a specific machine for vulnerabilities with vulnxscan and display CRITICAL CVEs
scan machine +args="":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p reports/{{ machine }}
    echo "Scanning {{ machine }} for vulnerabilities..."
    nix shell nixpkgs#sbomnix --command vulnxscan \
        .#nixosConfigurations.{{ machine }}.config.system.build.toplevel \
        -o reports/{{ machine }}/vulns.csv \
        {{ args }}
    echo "Vulnerability report written to reports/{{ machine }}/vulns.csv"
    if [ -f reports/{{ machine }}/vulns.csv ]; then
        nix shell nixpkgs#python3 --command python3 ./scripts/summarize-vulns.py reports/{{ machine }}/vulns.csv
    fi

# Scan all servers and systems for vulnerabilities
scan-all +args="":
    #!/usr/bin/env bash
    set -euo pipefail
    for machine in $(just _list_servers); do
        echo "=== Scanning $machine ==="
        just scan "$machine" {{ args }}
    done

