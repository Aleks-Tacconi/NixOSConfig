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
      libx11
      libxcomposite
      libxdamage
      libxfixes
      libxrandr
      libxtst
      libxscrnsaver
      at-spi2-atk
      expat
      fontconfig
      freetype
      libuuid
      libnotify
      libxcb
      libxcursor
      libxi
      libxrender
      libxext
    ];
  };
}
