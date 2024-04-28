# install

## formating

Get the format config:
```console
cd /tmp
curl https://raw.githubusercontent.com/hatch01/flake/master/disk.nix -o disk.nix
```

Get the disk id we want to format
```console
lsblk
```
The output shoud look like this:
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1     259:0    0   1,8T  0 disk
```

edit the `device` value according to your disk.
```console
vi /tmp/disk.nix
```

set the disk encryption password 
```console
echo -n "password" > /tmp/secret.key
```

Run partitionment:
```console
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disk.nix
```

Install
```console
su root
mkdir -p /mnt/etc
cd /mnt/etc
git clone https://github.com/hatch01/flake nixos
cd nixos
cp /tmp/disk.nix .
nixos-install --flake .#nixos-eymeric
```

Then install using this command replacing your disk
```bash
sudo nix run --extra-experimental-features "nix-command flakes" 'github:nix-community/disko#disko-install' -- --flake 'github:hatch01/flake#nixos-eymeric' --disk main /dev/sda
```
