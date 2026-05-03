{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [ mpvpaper ];

  wayland.windowManager.hyprland.settings.exec-once = [
    "pkill -x mpvpaper; mpvpaper -o \"no-audio loop-file=inf keepaspect=no\" '*' ~/wallpapers/wallpaper.gif &"
  ];
}
