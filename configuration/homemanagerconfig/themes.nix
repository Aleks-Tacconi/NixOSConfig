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
  wallpaperThemeDir = "${config.xdg.stateHome}/quickshell/wallpaper-theme";
  wallpaperPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pillow ]);
  wallpaperTheme = pkgs.writeShellScriptBin "quickshell-wallpaper-theme" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.glib
        pkgs.dbus
      ]
    }:$PATH"
    exec ${wallpaperPython}/bin/python ${./wallpaper_theme.py} \
      --notify --config ${lib.escapeShellArg config.xdg.configHome} \
      --output ${lib.escapeShellArg wallpaperThemeDir} \
      --kde ${kdeColorScheme} \
      --kvantum ${kvantumTheme}/share/Kvantum/${kvantumThemeName} \
      --image "$1"
  '';
  iconThemeName = "Papirus";
in
{
  home.packages = with pkgs; [
    kvantumTheme
    wallpaperTheme
    kdePackages.breeze
  ];

  # Home Manager maps qtct to qt5ct, but KDE Connect uses Qt 6.
  home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";

  home.file.".config/kdeglobals".source =
    config.lib.file.mkOutOfStoreSymlink "${wallpaperThemeDir}/kdeglobals";

  home.activation.initializeWallpaperTheme =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        if [ ! -f ${lib.escapeShellArg "${wallpaperThemeDir}/qt.conf"} ]; then
          $DRY_RUN_CMD ${wallpaperTheme}/bin/quickshell-wallpaper-theme ${./wallpapers/cypberpunk.jpg}
        fi
      '';

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
      theme = null;
      extraCss = ''
        :root {
          --window-bg-color: #141414;
          --view-bg-color: #101010;
          --headerbar-bg-color: #181818;
          --sidebar-bg-color: #181818;
          --card-bg-color: #202020;
          --dialog-bg-color: #202020;
        }
      '';
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
        custom_palette = true;
        color_scheme_path = "${wallpaperThemeDir}/qt.conf";
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "kvantum";
      };
    };
    qt6ctSettings = {
      Appearance = {
        custom_palette = true;
        color_scheme_path = "${wallpaperThemeDir}/qt.conf";
        icon_theme = iconThemeName;
        standard_dialogs = "xdgdesktopportal";
        style = "kvantum";
      };
    };
  };

  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=wallpaper
  '';
  home.file.".config/Kvantum/wallpaper".source =
    config.lib.file.mkOutOfStoreSymlink "${wallpaperThemeDir}/Kvantum/wallpaper";

  home.file.".hyprland-assets/icon.png".source = ./.icon.png;
  home.file.".hyprland-assets/wallpaper.jpg".source = ./wallpapers/cypberpunk.jpg;
}
