{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ libreoffice-fresh ];
}
