{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ papirus-icon-theme sierra-gtk-theme qt6Packages.qt6ct ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    style=gtk2
    color_scheme=dark
    icon_theme=Papirus-Dark
  '';

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=gtk2
    color_scheme=dark
    icon_theme=Papirus-Dark
  '';

  home.file.".icon.png".source =
    config.lib.file.mkOutOfStoreSymlink ./.icon.png;
  home.file.".logo.jpeg".source =
    config.lib.file.mkOutOfStoreSymlink ./.logo.jpeg;
  home.file.".wallpaper.jpg".source =
    config.lib.file.mkOutOfStoreSymlink ./.wallpaper.jpg;
}
