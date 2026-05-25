{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  fonts.packages = with pkgs; [
    font-awesome
    orbitron
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    inter
    noto-fonts-color-emoji
    roboto
    fira
    fira-sans
    google-fonts
    material-symbols
    readexpro
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "Noto Sans"
    ];
    serif = [ "DejaVu Serif" ];
    monospace = [
      "JetBrainsMono Nerd Font"
      "DejaVu Sans Mono"
    ];
  };
}
