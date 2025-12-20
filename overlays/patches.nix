stable: pkgs:
with pkgs;
(
  if stable then
    [ ]
  else
    [
      (fetchpatch2 {
        name = "openthread-border-router.patch";
        url = "https://github.com/NixOS/nixpkgs/pull/332296.diff";
        hash = "sha256-BK/0R3y6KLrMpRgqYAQgmXBrq0DH6K3shHDn/ibzaA8=";
      })

      # (fetchpatch2 {
      #   name = "cockpit.patch";
      #   url = "https://github.com/NixOS/nixpkgs/pull/447043.diff";
      #   hash = "sha256-vL4n6/DTr+or5GjAOxrUtEe9UtDXmhwXQ/cUlFfL/Tw=";
      # })
    ]
)
# Common patches for stable and unstable
++ [
  (fetchpatch2 {
    name = "cockpit-zfs.patch";
    url = "https://github.com/hatch01/nixpkgs/pull/5.diff";
    hash = "sha256-h2gy/AJsMNIMBOQ+PJlajun//aPY+1oMJtNqzWd8iVw=";
  })
  # Beszel
  (fetchpatch2 {
    name = "beszel-disk-systemd.patch";
    url = "https://github.com/hatch01/nixpkgs/pull/2.diff";
    hash = "sha256-2w9LHL3eQTQrandBmE/HywfFaHJTHk7g/mr+PmCXl7A=";
  })
]
