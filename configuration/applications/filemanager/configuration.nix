{ pkgs, ... }:

{
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };

  environment.systemPackages = with pkgs; [
    nautilus-python
    nautilus
    sushi
  ];

  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
