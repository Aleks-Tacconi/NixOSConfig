# Everyday shell, file, process, and Git utilities.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.callPackage ../../../packages/pommy { })
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
