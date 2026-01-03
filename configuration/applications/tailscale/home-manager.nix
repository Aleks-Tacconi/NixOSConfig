{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [
    tailscale
    tailscale-systray
  ];
}
