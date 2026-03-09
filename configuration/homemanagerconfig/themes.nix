{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [
    papirus-icon-theme
    sierra-gtk-theme
  ];

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

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.package = with pkgs; [
      libsForQt5.qtstyleplugins
      qt6Packages.qt6gtk2
    ];
    qt5ctSettings = {
      Appearance = {
        color_scheme = "dark";
        icon_theme = "Papirus-Dark";
        standard_dialogs = "xdgdesktopportal";
        style = "gtk2";
      };
    };
    qt6ctSettings = {
      Appearance = {
        color_scheme = "dark";
        icon_theme = "Papirus-Dark";
        standard_dialogs = "xdgdesktopportal";
        style = "gtk2";
      };
    };
    kde.settings = {
      kdeglobals = {
        General.ColorScheme = "BreezeDark";
        Icons.Theme = "Papirus-Dark";
        KDE.widgetStyle = "Breeze";
      };
    };
  };

  home.file.".icon.png".source = config.lib.file.mkOutOfStoreSymlink ./.icon.png;
  home.file.".logo.jpeg".source = config.lib.file.mkOutOfStoreSymlink ./.logo.jpeg;
  home.file.".wallpaper.png".source = config.lib.file.mkOutOfStoreSymlink ./.wallpaper.png;
}
