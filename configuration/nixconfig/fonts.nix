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
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
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
