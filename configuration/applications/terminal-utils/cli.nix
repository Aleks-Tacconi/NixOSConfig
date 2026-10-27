# Everyday shell, file, process, and Git utilities.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    zip
    unzip
    tree
    xdg-utils
    ripgrep
    fd
    fzf
    zoxide
    bat
    jq
    lsof
    htop
    wget
    ncdu
    lazygit
    gh
    mprocs
  ];
}
