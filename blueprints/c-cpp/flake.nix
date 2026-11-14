{
  description = "C and C++ development blueprint";

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
            gdb
            clang-tools
            valgrind
            cpplint
          ];

          shellHook = ''
            echo "C/C++ blueprint"
          '';
        };
      }
    );
}
