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
    Exec=nvim %F
    Icon=nvim
    NoDisplay=true
  '';

}
