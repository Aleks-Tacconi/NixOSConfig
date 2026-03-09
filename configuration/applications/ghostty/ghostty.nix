{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [ ghostty ];
  home.file.".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink ./ghostty;
}
