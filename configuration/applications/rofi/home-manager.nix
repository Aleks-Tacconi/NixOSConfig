{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ rofi ];

  home.file.".config/rofi".source = config.lib.file.mkOutOfStoreSymlink ./rofi;

  home.file.".local/share/applications/rofi-theme-selector.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Rofi Theme Selector
    Exec=rofi-theme-selector
    Icon=rofi
    NoDisplay=true
  '';

  home.file.".local/share/applications/rofi.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Rofi
    Exec=rofi -show drun
    Icon=rofi
    NoDisplay=true
  '';
}
