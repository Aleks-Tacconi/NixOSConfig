{ config, pkgs, inputs, lib, ... }:

{
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = { imports = [ ./home-manager.nix ]; };
  };
}
