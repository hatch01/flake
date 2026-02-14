(
  nixpkgs-unstable: final: prev:
  let
    unstable = import nixpkgs-unstable {
      system = prev.stdenv.hostPlatform.system;
      config = prev.config;
    };
    unstablePackages = [
      "beszel"
    ];
  in
  builtins.listToAttrs (
    map (x: {
      name = x;
      value = unstable.${x};
    }) unstablePackages
  )
)
