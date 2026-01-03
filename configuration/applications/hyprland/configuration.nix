{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  security.polkit.enable = true;
  programs.hyprland.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
