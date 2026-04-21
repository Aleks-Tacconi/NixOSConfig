{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  programs.opencode = {
    enable = false;
    package = pkgs.opencode;
  };
}
