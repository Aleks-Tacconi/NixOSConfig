{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.variables.NIXOS_HOST = "pc";

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  home-manager.users."aleks".wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      {
        output = "HDMI-A-2";
        mode = "1920x1080@60";
        position = "2560x0";
        scale = 1;
      }
      {
        output = "HDMI-A-1";
        mode = "2560x1440@60";
        position = "0x0";
        scale = 1;
      }
    ];

    workspace_rule = lib.mkForce [
      {
        workspace = "1";
        monitor = "HDMI-A-2";
        default = true;
      }
      {
        workspace = "2";
        monitor = "HDMI-A-2";
      }
      {
        workspace = "3";
        monitor = "HDMI-A-2";
      }
      {
        workspace = "4";
        monitor = "HDMI-A-2";
      }
      {
        workspace = "5";
        monitor = "HDMI-A-2";
      }
      {
        workspace = "6";
        monitor = "HDMI-A-2";
      }
      {
        workspace = "7";
        monitor = "HDMI-A-1";
        default = true;
      }
      {
        workspace = "8";
        monitor = "HDMI-A-1";
      }
      {
        workspace = "9";
        monitor = "HDMI-A-1";
      }
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
    ../configuration/nvidia/configuration.nix
  ];
  boot.loader.grub.useOSProber = true;
  time.hardwareClockInLocalTime = true;
}
