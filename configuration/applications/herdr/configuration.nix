{
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
