{
  description = "React+MUI flake";

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
            nodejs
            oxlint
          ];

          shellHook = ''
            echo "React+MUI blueprint"

            if [ -f package-lock.json ]; then
              echo "running npm ci"
              npm ci
            fi

            if [ ! -d ./node_modules ]; then
              echo "running init script"
              make init
            fi
          '';
        };
      }
    );
}
