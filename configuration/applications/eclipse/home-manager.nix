{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ eclipses.eclipse-java ];
}
