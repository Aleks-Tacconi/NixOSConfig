# C and C++ debugging, analysis, and editor tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    vscode-extensions.ms-vscode.cpptools-extension-pack
    vscode-extensions.ms-vscode.cpptools
    gdb
    clang-tools
    valgrind
    cpplint
  ];
}
