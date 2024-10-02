(
  nixpkgs-unstable: final: prev: let
    unstable = import nixpkgs-unstable {
      system = prev.system;
      config = prev.config;
    };
    unstablePackages = [
    ];
  in
    builtins.listToAttrs (map (x: {
        name = x;
        value = unstable.${x};
      })
      unstablePackages)
    // {
      mautrix-signal = prev.mautrix-signal.overrideAttrs rec {
        version = "0.7.1";
        src = prev.fetchFromGitHub {
          owner = "mautrix";
          repo = "signal";
          rev = "v${version}";
          hash = "sha256-OjWRdYAxjYMGZswwKqGKUwCIc5qHkNBTQgIcbiRquH0=";
        };
        vendorHash = "sha256-oV8ILDEyMpOZy5m2mnPAZj5XAhleO8yNz49wxvZboVs=";
      };
    }
)
