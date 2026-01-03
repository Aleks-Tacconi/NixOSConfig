{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  home.file.".local/share/applications/nvim.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Neovim (Wrapper)
    Exec=nvim %F
    Icon=nvim
    NoDisplay=true
  '';

}
