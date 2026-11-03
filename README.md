# install

## nixpkgs patches

Add a patch from the command line:

```console
just add-patch --name "fix foo" --pr 123456 --category unstable --commit --apply
just add-patch --name "use my branch" --branch my-branch --owner someone --commit
```

Or run the `Add nixpkgs patch` workflow from the Forgejo Actions tab and fill in
the form. The workflow adds the patch to `patches.nix`, applies all patches to
`nixpkgs-patched` unless `apply` is set to `no`, then pushes the changes to
`staging`.

## remote install

example:

```console
just remote-install cyclamen 2a01:4f9:c013:978b::1
```

## formatting

Get the format config:

```console
cd /tmp
curl https://raw.githubusercontent.com/hatch01/flake/master/disk.nix -o disk.nix
```

Get the disk id we want to format

```console
lsblk
```

The output should look like this:

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
```

maybe edit the disk name in flake .nix

You need to generate keys for secure boot:

```console
sudo sbctl create-keys
```

then install

```console
nixos-install --flake .#tulipe
```
