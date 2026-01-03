{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ wlogout ];

  home.file.".config/wlogout".source =
    config.lib.file.mkOutOfStoreSymlink ./wlogout;
}
