{ config, pkgs, lib, inputs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
  };
}
