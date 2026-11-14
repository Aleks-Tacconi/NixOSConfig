# Nix language server and formatter.
# Kept global so editing this NixOS configuration and any project flake.nix files
# always has LSP support and formatting available.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nil
    nixfmt
  ];
}
