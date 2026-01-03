{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [ ./zsh.nix ];

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_16;
  services.postgresql.authentication = ''
    local all all trust
  '';

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [
        ./shellutils.nix
        ./kitty.nix
      ];
    };
  };
}
