# Document conversion and the full TeX distribution.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pandoc
    texliveFull
  ];
}
