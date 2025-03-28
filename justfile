rebuild:
	# using impure to allow passing the env vars to nixos-rebuild
	NIXOS_LABEL=$(echo "$(git log -1 --pretty=format:%s)---$(git diff --name-only HEAD)" | paste -sd '-' | tr "/" "_" | tr " " "_" | sed 's/[^a-zA-Z0-9:_\.-]//g') nixos-rebuild switch --flake . --impure --use-remote-sudo

debug:
	# using impure to allow passing the env vars to nixos-rebuild
	NIXOS_LABEL=$(echo "$(git log -1 --pretty=format:%s)---$(git diff --name-only HEAD)" | paste -sd '-' | tr "/" "_" | tr " " "_" | sed 's/[^a-zA-Z0-9:_\.-]//g') nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

update +inputs="":
	nix flake update --commit-lock-file --accept-flake-config {{inputs}}

history:
	nix profile history --profile /nix/var/nix/profiles/system

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug

format machine:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko systems/{{machine}}/disk.nix

mount machine:
	sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount systems/{{machine}}/disk.nix

install machine:
	sudo nixos-install --flake .#{{machine}}

analyze:
	find -name "*.nix" | xargs -I{} nil diagnostics {}

forcast machine:
  nix-forecast -c ".#nixosConfigurations.{{machine}}" -b https://cache.onyx.ovh -b https://cache.nixos.org -b https://cuda-maintainers.cachix.org -b https://cache.saumon.network/proxmox-nixos

