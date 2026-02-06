{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  nixpkgs.config = {
    allowUnfree = true;
  };
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glib
      gtk3
      nss
      nspr
      dbus
      cups
      atk
      cairo
      pango
      gdk-pixbuf
      alsa-lib
      libdrm
      mesa
      libgbm
      libxkbcommon
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXrandr
      xorg.libXtst
      xorg.libXScrnSaver
      xorg.libxcb
      at-spi2-atk
      expat
      fontconfig
      freetype
      libuuid
      libnotify
      libxcb
      xorg.libXcursor
      xorg.libXi
      xorg.libXrender
      xorg.libXext
    ];
  };
}
