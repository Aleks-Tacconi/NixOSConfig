{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.variables.NIXOS_HOST = "laptop";

  home-manager.users."aleks".home.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
  };

  imports = [
    ./core.nix
    ./hardware-configuration-laptop.nix
    ../configuration/nixconfig/bluetooth.nix
    ../configuration/nixconfig/power_profiles.nix

    ../configuration/applications/vial/configuration.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];
}
