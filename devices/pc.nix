{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
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
