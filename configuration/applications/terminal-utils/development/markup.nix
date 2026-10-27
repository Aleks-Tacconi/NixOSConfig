# Markdown and QML editor tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    marksman
    markdownlint-cli
    kdePackages.qtdeclarative
    tree-sitter
  ];
}
