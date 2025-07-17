(
  nixpkgs-unstable: final: prev:
  let
    unstable = import nixpkgs-unstable {
      system = prev.system;
      config = prev.config;
    };
    unstablePackages = [
    ];
  in
  builtins.listToAttrs (
    map (x: {
      name = x;
      value = unstable.${x};
    }) unstablePackages
  )
)
