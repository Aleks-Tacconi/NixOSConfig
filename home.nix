{ ... }:

{
  home.username = "aleks";
  home.homeDirectory = "/home/aleks";
  home.stateVersion = "25.05";

  imports = [
    ./configuration/homemanagerconfig/envvars.nix
    ./configuration/homemanagerconfig/themes.nix
    ./configuration/homemanagerconfig/desktopentries.nix
  ];
}
