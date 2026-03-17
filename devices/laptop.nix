{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.ollama.enable = true;

  home-manager.users."aleks".wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "eDP-1, 1920x1200@60, 0x0, 1"
      "DP-1, 1920x1080@60, -1920x0, 1"
    ];

    workspace = lib.mkForce [
      "1, monitor:eDP-1, default:true"
      "2, monitor:eDP-1"
      "3, monitor:eDP-1"
      "4, monitor:eDP-1"
      "5, monitor:eDP-1"
      "6, monitor:eDP-1"
      "7, monitor:DP-1, default:true"
      "8, monitor:DP-1"
      "9, monitor:DP-1"
    ];
  };

  imports = [
    ./core.nix
    ./hardware-configuration-laptop.nix
    ../configuration/applications/eww/configuration-laptop.nix
    ../configuration/nixconfig/bluetooth.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];
}
