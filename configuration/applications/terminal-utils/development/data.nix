# SQL and XML formatting, validation, and editor tooling.
# Kept global because database CLI inspection (sqlite), XML/SQL formatting,
# and editor LSPs are used across many projects and ad-hoc tasks rather than one stack.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    postgres-language-server
    sqlfluff
    pgformatter
    sqlite
    libxml2
    lemminx
  ];
}
