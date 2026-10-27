# Julia runtime.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    julia_111-bin
  ];
}
