{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ eza ];

  home.file.".config/eza".source =
    config.lib.file.mkOutOfStoreSymlink ./eza;
}
