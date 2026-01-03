{ config, pkgs, inputs, lib, ... }:

{
  services.syncthing.openDefaultPorts = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = { imports = [ ./home-manager.nix ]; };
  };

}
