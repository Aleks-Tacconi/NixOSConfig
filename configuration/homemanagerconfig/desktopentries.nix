{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.file.".local/share/applications/uuctl.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=User Utility Manager
    Exec=uuctl
    Icon=preferences-system
    NoDisplay=true
  '';

  home.file.".local/share/applications/nixos-manual.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=NixOS Manual
    Exec=nixos-help
    Icon=help-browser
    NoDisplay=true
  '';

  home.file.".local/share/applications/jellyfin-laptop.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Jellyfin Laptop
    Exec=sh -c "brave --app="http://laptop:8096""
    Icon=mpv
  '';

  home.file.".local/share/applications/jellyfin-pc.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Jellyfin PC
    Exec=sh -c "brave --app="http://pc:8096""
    Icon=mpv
  '';

  home.file.".local/share/applications/julia.desktop".text = ''
    [Desktop Entry]
    Name=Julia
    Comment=High-performance language for technical computing
    Exec=julia
    Icon=julia
    Terminal=true
    Type=Application
    Categories=Development;
    Name[en_GB.UTF-8]=Julia
    X-GNOME-FullName[en_GB.UTF-8]=Julia
    Comment[en_GB.UTF-8]=High-performance language for technical computing
    NoDisplay=true
    Path=
    X-GNOME-UsesNotifications=false
  '';

  home.file.".local/share/applications/tracy.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=Tracy Profiler
    GenericName=Code profiler
    Comment=Examine code to see where it is slow
    Exec=tracy %f
    Icon=tracy
    Terminal=false
    Categories=Profiling;Development;
    MimeType=application/tracy;
    Name[en_GB.UTF-8]=Tracy Profiler
    X-GNOME-FullName[en_GB.UTF-8]=Tracy Profiler
    Comment[en_GB.UTF-8]=Examine code to see where it is slow
    NoDisplay=true
    Path=
    X-GNOME-UsesNotifications=false
  '';
}
