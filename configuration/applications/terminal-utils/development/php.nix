# PHP runtime and Composer.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    php84Packages.composer
    php
  ];
}
