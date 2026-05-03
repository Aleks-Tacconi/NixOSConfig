{ config, pkgs, lib, inputs, ... }:

{
  home.file.".local/share/applications/whatsapp.desktop".text =
    ''
      [Desktop Entry]
      Name=Whatsapp
      Comment=
      Exec=zen "https://web.whatsapp.com/"
      Terminal=false
      Type=Application
      Categories=Messages;
    '';
}
