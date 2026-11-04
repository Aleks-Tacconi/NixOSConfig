{
  description = "Python flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            (python3.withPackages (
              ps: with ps; [
                # Linter + Formatter
                ruff

                # Python Testing
                pytest
                hypothesis

                # Packages
                requests
              ]
            ))

            pyright
          ];

          shellHook = ''
            echo "Python blueprint"
          '';
        };
      }
    );
}
