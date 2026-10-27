# Nix language server and formatter.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil
    nixfmt
  ];
}
