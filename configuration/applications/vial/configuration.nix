{ pkgs, ... }:

{
  hardware.keyboard.qmk.enable = true;

  services.udev.packages = with pkgs; [
    vial
  ];

  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
