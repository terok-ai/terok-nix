{ pkgs }:
let
  shells = {
    default = shells.edit-packaging;
    edit-packaging = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        git
        pre-commit
        nixfmt
        cabal-install
        ghc
            lf
      ];
    };
  };
in
shells
