{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment.systemPackages = with pkgs; [
    nautilus-python
    nautilus
    sushi
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
