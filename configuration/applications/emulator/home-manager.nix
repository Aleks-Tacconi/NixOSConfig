{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    dolphin-emu
    melonds
  ];
}
