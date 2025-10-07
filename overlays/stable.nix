(
  nixpkgs-stable: final: prev:
  let
    stable = import nixpkgs-stable {
      system = prev.system;
      config = prev.config;
    };
    stablePackages = [
    ];
  in
  builtins.listToAttrs (
    map (x: {
      name = x;
      value = stable.${x};
    }) stablePackages
  )
)
