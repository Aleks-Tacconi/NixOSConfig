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
    ./hardware-configuration-laptop.nix
    ../configuration/applications/eww/configuration-laptop.nix
    ../configuration/nixconfig/bluetooth.nix
    ../configuration/applications/steam/configuration.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];
}
