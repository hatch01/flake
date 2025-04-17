(pkgs: final: prev: {
  hyperhdr = pkgs.callPackage ./hyperhdr.nix {};
  linalg = pkgs.callPackage ./linalg.nix {};
  lunasvg = pkgs.callPackage ./lunasvg.nix {};
  plutovg = pkgs.callPackage ./plutovg.nix {};
})
