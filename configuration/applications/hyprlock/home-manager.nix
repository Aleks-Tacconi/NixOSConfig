{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ hyprlock ];

  home.file.".config/hypr/hyprlock.conf".source = 
    config.lib.file.mkOutOfStoreSymlink ./hyprlock.conf;
}
