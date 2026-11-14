# Markdown and QML editor tooling.
# Kept global because editing this NixOSConfig (docs, READMEs, and Quickshell QML modules)
# and Neovim syntax highlighting (tree-sitter) rely on these tools outside project flakes.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    marksman
    markdownlint-cli
    kdePackages.qtdeclarative
    tree-sitter
  ];
}
