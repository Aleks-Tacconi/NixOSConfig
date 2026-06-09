{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = with pkgs; [
    neovim
  ];

  home.file.".local/share/applications/nvim.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Neovim (Wrapper)
    Exec=ghostty -e nvim %F
    Icon=nvim
    NoDisplay=true
    MimeType=text/plain;text/markdown;text/x-c;text/x-c++;text/x-chdr;text/x-csrc;text/x-python;text/x-shellscript;application/json;application/xml;application/yaml;text/css;text/html;
  '';

}
