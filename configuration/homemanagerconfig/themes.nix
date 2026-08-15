{
  config,
  pkgs,
  lib,
  ...
}:

let
  gtkTheme = pkgs.catppuccin-gtk.override {
    accents = [ "red" ];
    size = "standard";
    tweaks = [ "rimless" ];
    variant = "mocha";
  };
  kvantumTheme = pkgs.catppuccin-kvantum.override {
    accent = "red";
    variant = "mocha";
  };
  gtkThemeName = "catppuccin-mocha-red-standard+rimless";
  iconThemeName = "Papirus";
  kvantumThemeName = "Catppuccin-Mocha-Red";
in
{
  home.packages = with pkgs; [
    papirus-icon-theme
    gtkTheme
    kvantumTheme
    kdePackages.breeze
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
  ];

  # Home Manager maps qtct to qt5ct, but KDE Connect uses Qt 6.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";

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
      package = gtkTheme;
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
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
    ];
    qt5ctSettings = {
      Appearance = {
        color_scheme = "dark";
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "kvantum";
      };
    };
    qt6ctSettings = {
      Appearance = {
        color_scheme = "dark";
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "kvantum";
      };
    };
    kde.settings.kdeglobals = {
      General.ColorScheme = "BreezeDark";
      Icons.Theme = iconThemeName;
      KDE.widgetStyle = "kvantum";
    };
  };

  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=${kvantumThemeName}
  '';

  home.file.".hyprland-assets/icon.png".source = ./.icon.png;
  home.file.".hyprland-assets/wallpaper.jpg".source = ./wallpapers/moon.jpg;
}
