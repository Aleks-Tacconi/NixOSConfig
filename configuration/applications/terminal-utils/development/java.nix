# Java build, formatting, and editor tooling.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jdt-language-server
    lombok
    checkstyle
    google-java-format
    maven
  ];
}
