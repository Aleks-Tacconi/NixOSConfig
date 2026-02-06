{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  nixpkgs.config.android_sdk.accept_license = true;

  imports = [
    ./core.nix
    ./hardware-configuration-pc.nix

    ../configuration/applications/steam/configuration.nix
    ../configuration/nvidia/configuration.nix
    ../configuration/applications/eww/configuration-pc.nix
  ];
  boot.loader.grub.useOSProber = true;
  time.hardwareClockInLocalTime = true;
}
