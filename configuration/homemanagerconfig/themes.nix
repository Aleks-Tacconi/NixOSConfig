{
  config,
  pkgs,
  ...
}:

let
  gtkThemeName = "WhiteSur-Dark";
  iconThemeName = "Papirus-Dark";
in
{
  home.packages = with pkgs; [
    papirus-icon-theme
    whitesur-gtk-theme
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
      name = gtkThemeName;
      package = pkgs.whitesur-gtk-theme;
    };
    gtk4 = {
      theme = config.gtk.theme;
    };
    iconTheme = {
      name = iconThemeName;
      package = pkgs.papirus-icon-theme;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = gtkThemeName;
      icon-theme = iconThemeName;
      font-name = "Noto Sans 11";
      document-font-name = "Noto Sans 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
    };
    "org/gnome/shell/extensions/user-theme" = {
      name = gtkThemeName;
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
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "gtk2";
      };
    };
    qt6ctSettings = {
      Appearance = {
        color_scheme = "dark";
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "gtk2";
      };
    };
    kde.settings = {
      kdeglobals = {
        General.ColorScheme = "BreezeDark";
        Icons.Theme = iconThemeName;
        KDE.widgetStyle = "Breeze";
      };
    };
  };

  home.file.".icon.png".source = config.lib.file.mkOutOfStoreSymlink ./.icon.png;
  home.file.".logo.jpeg".source = config.lib.file.mkOutOfStoreSymlink ./.logo.jpeg;
  home.file.".wallpaper-current".source =
    config.lib.file.mkOutOfStoreSymlink ./wallpapers/wallpaper.png;
  home.file."wallpapers".source = config.lib.file.mkOutOfStoreSymlink ./wallpapers;
}
