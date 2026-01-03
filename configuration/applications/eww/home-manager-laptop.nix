{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ eww ];

  home.file.".config/eww".source =
    config.lib.file.mkOutOfStoreSymlink ./eww-laptop;
}
