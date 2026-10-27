# Shared native build tools and libraries.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gnumake
    gcc
    libgcc
    libGL
    glibc
    glib
    rubyPackages.glib2
    stdenv.cc.cc.lib
    zlib
    icu
  ];
}
