{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.variables.NIXOS_HOST = "laptop";

  services.ollama.enable = true;

  home-manager.users."aleks".home.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    LD_LIBRARY_PATH = lib.mkForce "${pkgs.libglvnd}/lib:${pkgs.gcc.cc.lib}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
  };

  home-manager.users."aleks".wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      {
        output = "eDP-1";
        mode = "1920x1200@60";
        position = "0x0";
        scale = 1;
      }
      {
        output = "DP-2";
        mode = "1920x1080@60";
        position = "-1920x0";
        scale = 1;
      }
    ];

    workspace_rule = lib.mkForce [
      {
        workspace = "1";
        monitor = "eDP-1";
        default = true;
      }
      {
        workspace = "2";
        monitor = "eDP-1";
      }
      {
        workspace = "3";
        monitor = "eDP-1";
      }
      {
        workspace = "4";
        monitor = "eDP-1";
      }
      {
        workspace = "5";
        monitor = "eDP-1";
      }
      {
        workspace = "6";
        monitor = "eDP-1";
      }
      {
        workspace = "7";
        monitor = "DP-2";
        default = true;
      }
      {
        workspace = "8";
        monitor = "DP-2";
      }
      {
        workspace = "9";
        monitor = "DP-2";
      }
    ];
  };

  imports = [
    ./core.nix
    ./hardware-configuration-laptop.nix
    ../configuration/nixconfig/bluetooth.nix

    ../configuration/applications/vial/configuration.nix
    ../configuration/applications/emulator/configuration.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];
}
