{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [
    samba
    legendary-gl
    rare
    wineWowPackages.waylandFull
  ];
}
