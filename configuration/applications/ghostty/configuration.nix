{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [ ../kitty/zsh.nix ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [
        ../kitty/shellutils.nix
        ./ghostty.nix
      ];
    };
  };
}
