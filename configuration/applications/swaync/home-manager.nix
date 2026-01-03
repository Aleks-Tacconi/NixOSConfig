{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ swaynotificationcenter ];

  home.file.".config/swaync".source =
    config.lib.file.mkOutOfStoreSymlink ./swaync;
}
