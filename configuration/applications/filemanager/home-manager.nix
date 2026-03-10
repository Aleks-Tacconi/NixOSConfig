{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.file.".local/share/applications/org.gnome.Nautilus.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Nautilus
    GenericName=File Manager
    Exec=nautilus %U
    Icon=system-file-manager
    Categories=Utility;FileManager;
  '';
}
