{
  description = "Python notebook dev shell for molten-nvim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };

      python = pkgs.python313.withPackages (ps: with ps; [
        pynvim
        jupyter
        ipykernel
        jupyter-client
        jupytext

        numpy
        pandas
        matplotlib
        scipy
        scikit-learn
      ]);

      kernelSpec = pkgs.runCommand "jupyter-kernel-ml" {} ''
        mkdir -p $out/share/jupyter/kernels/machine-learning
        cat <<EOF > $out/share/jupyter/kernels/machine-learning/kernel.json
        {
          "argv": [
            "${python}/bin/python",
            "-m",
            "ipykernel_launcher",
            "-f",
            "{connection_file}"
          ],
          "display_name": "Python 3 (ML Nix Flake)",
          "language": "python",
          "metadata": {
            "debugger": true
          }
        }
        EOF
      '';
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          python
          kernelSpec
        ];

        shellHook = ''
          export JUPYTER_PATH="${kernelSpec}/share/jupyter:${python}/share/jupyter''${JUPYTER_PATH:+:$JUPYTER_PATH}"
        '';
      };
    };
}

