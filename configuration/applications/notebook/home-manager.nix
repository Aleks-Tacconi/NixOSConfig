{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  currentPythonKernel = pkgs.runCommand "jupyter-current-python-kernel" { } ''
    mkdir -p $out/share/jupyter/kernels/current-python

    cat > $out/share/jupyter/kernels/current-python/kernel.json <<EOF
    {
      "argv": [
        "python",
        "-m",
        "ipykernel_launcher",
        "-f",
        "{connection_file}"
      ],
      "display_name": "Current Python",
      "language": "python"
    }
EOF
  '';
  patchedQuarto = pkgs.quarto.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace bin/quarto.js \
        --replace-fail "syntax-highlighting" "highlight-style"
    '';
  });
in
{
  home.packages = with pkgs; [
    # Jupyter Python packages live in terminal-utils/shellutils.nix (single env)

    # Kernel definition
    currentPythonKernel

    # Document rendering & PDF export tools
    patchedQuarto
    typst
  ];

  home.file.".local/share/jupyter/runtime/.keep".text = "";
}
