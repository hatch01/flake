# install
```bash
lsblk
```
Pick the disk name where you want to install the things

Then install using this command replacing your disk
```bash
sudo nix run 'github:nix-community/disko#disko-install' -- --flake 'github:hatch01/flake#nixos-eymeric' --disk main /dev/sda
```
