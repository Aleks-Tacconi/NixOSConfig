# Desktop integration, Wayland, power, and media helpers.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    orca
    hyprshot
    wl-clipboard
    brightnessctl
    desktop-file-utils
    libnotify
    kdePackages.wayland-protocols
    upower
    wlr-protocols
    xwayland-run
    playerctl
    ffmpeg
    gcalcli
  ];
}
