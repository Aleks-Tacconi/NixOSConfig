{
  config,
  pkgs,
  lib,
  ...
}:

let
  gtkThemeName = "catppuccin-mocha-red-charcoal";
  gtkTheme = pkgs.runCommand gtkThemeName { } ''
    base="${
      pkgs.catppuccin-gtk.override {
        accents = [ "red" ];
        size = "standard";
        tweaks = [
          "black"
          "rimless"
        ];
        variant = "mocha";
      }
    }/share/themes/catppuccin-mocha-red-standard+black,rimless"
    outdir="$out/share/themes/${gtkThemeName}"
    mkdir -p "$outdir"
    cp -r "$base"/* "$outdir/"
    chmod -R u+w "$outdir"
    find "$outdir" -name "*.css" -exec sed -i -e 's/#010101/#141414/gI' -e 's/#000000/#101010/gI' {} +
    sed -i "s/catppuccin-mocha-red-standard+black,rimless/${gtkThemeName}/g" "$outdir/index.theme"
  '';
  kvantumThemeName = "catppuccin-mocha-red-charcoal";
  kvantumTheme = pkgs.runCommand kvantumThemeName { } ''
    dir="$out/share/Kvantum/${kvantumThemeName}"
    mkdir -p "$dir"
    src="${
      pkgs.catppuccin-kvantum.override {
        accent = "red";
        variant = "mocha";
      }
    }/share/Kvantum/catppuccin-mocha-red"
    sed -e "s/#1E1E2E/#141414/gI" \
        -e "s/#181825/#101010/gI" \
        -e "s/#313244/#202020/gI" \
        -e "s/#45475A/#2c2c2c/gI" \
        -e "s/#585B70/#3c3c3c/gI" \
        "$src/catppuccin-mocha-red.kvconfig" > "$dir/${kvantumThemeName}.kvconfig"

    sed -e "s/#1E1E2E/#141414/gI" \
        -e "s/#181825/#101010/gI" \
        -e "s/#313244/#202020/gI" \
        -e "s/#45475A/#2c2c2c/gI" \
        -e "s/#585B70/#333333/gI" \
        "$src/catppuccin-mocha-red.svg" > "$dir/${kvantumThemeName}.svg"
  '';
  kdeColorScheme = pkgs.runCommand "catppuccin-mocha-red-charcoal.colors" { } ''
    src="${
      pkgs.catppuccin-kde.override {
        accents = [ "red" ];
        flavour = [ "mocha" ];
      }
    }/share/color-schemes/CatppuccinMochaRed.colors"
    sed -e 's/30, 30, 46/20, 20, 20/g' \
        -e 's/24, 24, 37/16, 16, 16/g' \
        -e 's/17, 17, 27/14, 14, 14/g' \
        -e 's/49, 50, 68/32, 32, 32/g' \
        "$src" > "$out"
  '';
  iconThemeName = "Papirus";
in
{
  home.packages = with pkgs; [
    kvantumTheme
    kdePackages.breeze
  ];

  # Home Manager maps qtct to qt5ct, but KDE Connect uses Qt 6.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";

  home.file.".config/kdeglobals".source = kdeColorScheme;

  home.pointerCursor = {
    enable = true;
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

  xdg.configFile."gtk-4.0/assets".source = "${gtkTheme}/share/themes/${gtkThemeName}/gtk-4.0/assets";

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
  };

  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=${kvantumThemeName}
  '';
  home.file.".config/Kvantum/${kvantumThemeName}".source =
    "${kvantumTheme}/share/Kvantum/${kvantumThemeName}";

  home.file.".hyprland-assets/icon.png".source = ./.icon.png;
  home.file.".hyprland-assets/wallpaper.jpg".source = ./wallpapers/cypberpunk.jpg;
}
