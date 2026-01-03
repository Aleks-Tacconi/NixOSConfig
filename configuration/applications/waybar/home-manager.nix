{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ waybar ];

  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink ./waybar;
}
