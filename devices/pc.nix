{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.variables.NIXOS_HOST = "pc";

  environment.systemPackages = with pkgs; [
    discord
    libxcb
    eden
    claude-code
    codex
    sunshine
    moonlight-qt
  ];

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
    ../configuration/applications/sunshine/configuration.nix
    ../configuration/applications/whatsapp/configuration.nix
    ../configuration/nvidia/configuration.nix
  ];
  boot.loader.grub.useOSProber = true;
  time.hardwareClockInLocalTime = true;
  programs.steam.enable = true;
}
