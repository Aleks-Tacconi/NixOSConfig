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
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
