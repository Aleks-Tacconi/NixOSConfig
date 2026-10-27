# SQL and XML formatting, validation, and editor tooling.
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
