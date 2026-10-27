# Python environment, Jupyter, and Python tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        debugpy
        demjson3
        numpy
        regex
        stdenv
        pip
        pynvim
        nbformat
        pillow
        pyperclip
        pylatexenc
        virtualenv
        ipykernel
        jupyter-client
        jupytext
        nbconvert
        notebook
        jupyterlab
      ]
    ))
    pipx
    black
    isort
    poetry
    pylint
    uv
    pyright
  ];

  home.file.".pylintrc".text = ''
    [MESSAGES CONTROL]
    disable=C0111,C0103
  '';
}
