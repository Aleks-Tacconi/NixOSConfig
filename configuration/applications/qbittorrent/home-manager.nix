{ config, pkgs, lib, inputs, ... }:

{
  # TODO: get a theme
  home.packages = with pkgs; [ qbittorrent ];
}
