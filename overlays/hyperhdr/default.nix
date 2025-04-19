(final: prev: {
  hyperhdr = prev.callPackage ./hyperhdr.nix {};
  linalg = prev.callPackage ./linalg.nix {};
  lunasvg = prev.callPackage ./lunasvg.nix {};
  plutovg = prev.callPackage ./plutovg.nix {};
})
