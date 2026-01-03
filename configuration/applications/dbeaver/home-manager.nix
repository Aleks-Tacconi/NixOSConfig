{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ dbeaver-bin ];

  home.file.".local/share/applications/dbeaver.desktop".text = ''
    [Desktop Entry]
    Name=DBeaver
    Comment=Universal Database Manager
    Exec=env GTK_THEME=Adwaita:dark dbeaver
    Icon=dbeaver
    Terminal=false
    Type=Application
    Categories=Development;Database;
  '';
}
