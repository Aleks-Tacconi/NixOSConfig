{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [ wasistlos ];
  home.file.".local/share/applications/com.github.xeco23.WasIstLos.desktop".text =
    ''
      [Desktop Entry]
      Name=Whatsapp
      Comment=
      Exec=brave --app="https://web.whatsapp.com/"
      Icon=com.github.xeco23.WasIstLos
      Terminal=false
      Type=Application
      Categories=Messages;
    '';
}
