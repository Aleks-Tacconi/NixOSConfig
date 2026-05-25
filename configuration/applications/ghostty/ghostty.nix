{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  homeConfigDir = "${config.home.homeDirectory}/NixOSConfig/configuration/applications/ghostty/ghostty";
in
{
  home.packages = with pkgs; [ ghostty ];
  home.file.".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink homeConfigDir;
}
