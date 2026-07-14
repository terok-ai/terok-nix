{
  pkgs ? import <nixpkgs>,
  overlays ? [ ],
  system ? builtins.currentSystem,
}:

let
  terok-overlay = import ./terok-overlay.nix;
  enable-tests-overlay = _: _: {
    enable-terok-checks = true;
  };

in
pkgs {
  overlays = overlays ++ [
    terok-overlay
  ];
  inherit system;
}
// {
  with-checks = pkgs {
    overlays = overlays ++ [
      terok-overlay
      enable-tests-overlay
    ];
    inherit system;
  };
}
