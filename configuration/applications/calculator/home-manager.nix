{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ gnome-calculator ];

  home.file.".local/share/applications/org.gnome.Calculator.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Calculator
    Exec=env GTK_THEME="WhiteSur-Dark" gnome-calculator %U
    Icon=org.gnome.Calculator
    Categories=GNOME;GTK;Utility;Calculator;
  '';
}
