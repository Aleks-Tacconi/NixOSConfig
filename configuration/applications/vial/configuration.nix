{ config, pkgs, inputs, lib, ... }:

{
  hardware.keyboard.qmk.enable = true;

  services.udev.packages = with pkgs; [
    vial
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = { imports = [ ./home-manager.nix ]; };
  };
}
