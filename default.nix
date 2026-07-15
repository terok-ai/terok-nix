{
  pkgs ? import <nixpkgs>,
  overlays ? [ ],
  system ? builtins.currentSystem,
}:

let
  terok-overlay = import ./terok-overlay.nix;
  make-packages =
    # boolean
    enable-terok-checks:
    let
      enable-checks-overlay = _: _: { inherit enable-terok-checks; };
    in
    pkgs {
      overlays = overlays ++ [
        terok-overlay
        enable-checks-overlay
      ];
      inherit system;
    };

in
make-packages false
// {
  with-checks = make-packages true;
}
