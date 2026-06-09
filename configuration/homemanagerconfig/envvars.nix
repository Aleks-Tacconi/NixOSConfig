let
  browser = "helium.desktop";
  editor = "nvim.desktop";
  imageEditor = "gimp.desktop";
  office = "onlyoffice-desktopeditors.desktop";
in
{
  config,
  pkgs,
  ...
}:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "helium";
    TERMINAL = "ghostty";
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
    NIXOS_OZONE_WL = "1";

    GSK_RENDERER = "opengl";
    ADW_DISABLE_PORTAL = "1";

    HYPRSHOT_DIR = "/home/aleks/Photos";

    # Add gcc libraries to LD_LIBRARY_PATH for Python packages with C extensions
    LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = [ browser ];
      "text/html" = [ browser ];
      "x-scheme-handler/about" = [ browser ];
      "x-scheme-handler/http" = [ browser ];
      "x-scheme-handler/https" = [ browser ];
      "x-scheme-handler/unknown" = [ browser ];

      "application/json" = [ editor ];
      "application/toml" = [ editor ];
      "application/xml" = [ editor ];
      "application/yaml" = [ editor ];
      "text/css" = [ editor ];
      "text/lua" = [ editor ];
      "text/csv" = [ editor ];
      "text/markdown" = [ editor ];
      "text/plain" = [ editor ];
      "text/x-c" = [ editor ];
      "text/x-c++" = [ editor ];
      "text/x-chdr" = [ editor ];
      "text/x-csrc" = [ editor ];
      "text/x-go" = [ editor ];
      "text/x-java" = [ editor ];
      "text/x-python" = [ editor ];
      "text/x-rust" = [ editor ];
      "text/x-shellscript" = [ editor ];

      "image/avif" = [ imageEditor ];
      "image/bmp" = [ imageEditor ];
      "image/gif" = [ imageEditor ];
      "image/jpeg" = [ imageEditor ];
      "image/png" = [ imageEditor ];
      "image/svg+xml" = [ imageEditor ];
      "image/tiff" = [ imageEditor ];
      "image/webp" = [ imageEditor ];

      "application/pdf" = [ office ];
      "application/msword" = [ office ];
      "application/rtf" = [ office ];
      "application/vnd.ms-excel" = [ office ];
      "application/vnd.ms-powerpoint" = [ office ];
      "application/vnd.oasis.opendocument.presentation" = [ office ];
      "application/vnd.oasis.opendocument.spreadsheet" = [ office ];
      "application/vnd.oasis.opendocument.text" = [ office ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ office ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ office ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ office ];
    };
  };
}
