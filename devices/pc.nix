{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.ollama = {
    enable = false;
    package = pkgs.ollama-cuda;
  };

  home-manager.users."aleks".wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "HDMI-A-1, 2560x1440@60, 1920x0, 1"
      "HDMI-A-2, 1920x1080@60, 0x0, 1"
    ];

    workspace = lib.mkForce [
      "1, monitor:HDMI-A-1, default:true"
      "2, monitor:HDMI-A-1"
      "3, monitor:HDMI-A-1"
      "4, monitor:HDMI-A-1"
      "5, monitor:HDMI-A-1"
      "6, monitor:HDMI-A-1"
      "7, monitor:HDMI-A-2, default:true"
      "8, monitor:HDMI-A-2"
      "9, monitor:HDMI-A-2"
    ];
  };

  fileSystems."/media/aleks" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  imports = [
    ./core.nix
    ./hardware-configuration-pc.nix

    ../configuration/applications/emulator/configuration.nix
    ../configuration/applications/steam/configuration.nix
    ../configuration/nvidia/configuration.nix
    ../configuration/applications/eww/configuration-pc.nix
  ];
  boot.loader.grub.useOSProber = true;
  time.hardwareClockInLocalTime = true;
}
