{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./core.nix
    ./hardware-configuration-pc.nix

    ../configuration/applications/steam/configuration.nix
    ../configuration/applications/lutris/configuration.nix
    ../configuration/nvidia/configuration.nix
    ../configuration/applications/eww/configuration-pc.nix
  ];
  boot.loader.grub.useOSProber = true;
  time.hardwareClockInLocalTime = true;
}
