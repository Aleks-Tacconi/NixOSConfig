{ config, pkgs, inputs, lib, ... }:

{
  home.packages = with pkgs; [ kitty ];
  home.file.".config/kitty".source =
    config.lib.file.mkOutOfStoreSymlink ./kitty;
}
