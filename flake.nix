{
  description = "Terok Nix package distribution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = self.legacyPackages.${system};
      in
      {
        legacyPackages = import ./. {
          pkgs = import nixpkgs;
          inherit system;
        };
        devShells = import ./devShells {
          inherit pkgs;
        };
        formatter =
          let
            config = self.checks.${system}.pre-commit-check.config;
            inherit (config) package configFile;
            script = ''
              if (( $# == 0 )); then
                files=(--all-files)
              else
                files=(--files "$@")
              fi
              ${pkgs.lib.getExe package} run --config ${configFile} "''${files[@]}"
            '';
          in
          pkgs.writeShellScriptBin "pre-commit-run" script;
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;
            };
          };
          inherit (pkgs.with-checks) terok;
          terok-without-checks = pkgs.terok;
        };
      }
    )
    // {
      overlays.default = import ./terok-overlay.nix;
    };
}
