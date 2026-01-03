{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ teams-for-linux ];
}
