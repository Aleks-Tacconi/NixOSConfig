{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # controller tooling

    bluez
    usbutils
    pciutils
    linuxConsoleTools
  ];
}
