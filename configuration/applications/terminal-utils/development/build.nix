# Shared native build tools and libraries.
# Kept global because general CLI utilities, Neovim plugins (e.g. telescope-fzf-native, treesitter),
# and ad-hoc native builds expect a C toolchain and core shared libraries on PATH.
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
