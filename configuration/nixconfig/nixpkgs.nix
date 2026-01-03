{ config, pkgs, inputs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
}
