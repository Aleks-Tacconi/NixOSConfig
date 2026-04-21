{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [ ./zsh.nix ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [
        ./shellutils.nix
        ./git.nix
      ];
    };
  };
}
