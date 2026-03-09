{
  config,
  pkgs,
  ...
}:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "zen";
    TERMINAL = "kitty";
    FILEMANAGER = "nautilus";

    XCURSOR_SIZE = "24";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    MOZ_ENABLE_WAYLAND = "1";
    GDK_SCALE = "1";
    SDL_VIDEODRIVER = "wayland";

    ELECTRON_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";

    GSK_RENDERER = "opengl";
    GTK_THEME = "WhiteSur-Dark";
    ADW_DISABLE_PORTAL = "1";

    HYPRSHOT_DIR = "/home/aleks/Photos/";

    # Add gcc libraries to LD_LIBRARY_PATH for Python packages with C extensions
    LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = [ "zen.desktop" ];
      "text/html" = [ "zen.desktop" ];
      "x-scheme-handler/about" = [ "zen.desktop" ];
      "x-scheme-handler/http" = [ "zen.desktop" ];
      "x-scheme-handler/https" = [ "zen.desktop" ];
      "x-scheme-handler/unknown" = [ "zen.desktop" ];
    };
  };
}
