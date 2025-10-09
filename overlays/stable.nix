(
  nixpkgs-stable: final: prev:
  let
    stable = import nixpkgs-stable {
      system = prev.system;
      config = prev.config;
    };
    stablePackages = [
      "matrix-synapse-wrapped"
      "matrix-synapse"
      "rlottie"
      "pdfarranger"
    ];

  in
  (builtins.listToAttrs (
    map (x: {
      name = x;
      value = stable.${x};
    }) stablePackages
  ))
  // rec {
    python3 = prev.python3.override {
      packageOverrides = python-final: python-prev: {
        sphinx-prompt = stable.python3Packages.sphinx-prompt;
      };
    };
    python3Packages = python3.pkgs;
  } // {
    jetbrains = stable.jetbrains;
}

)
