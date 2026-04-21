{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # services.postgresql.enable = true;
  # services.postgresql.package = pkgs.postgresql_16;
  # services.postgresql.authentication = ''
  #   local all all trust
  # '';

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./kitty.nix ];
    };
  };
}
