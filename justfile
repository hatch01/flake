rebuild:
	nixos-rebuild switch --flake . --use-remote-sudo

debug:
	nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

update:
	nix flake update --commit-lock-file --accept-flake-config

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
  nix-forecast -c ".#nixosConfigurations.{{machine}}" -b https://cache.onyx.ovh
