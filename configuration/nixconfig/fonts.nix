{ config, pkgs, inputs, lib, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    roboto
    fira
    fira-sans
  ];
}
