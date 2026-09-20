{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.antigravity-cli
  ];

  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
