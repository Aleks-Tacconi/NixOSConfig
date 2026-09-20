{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
