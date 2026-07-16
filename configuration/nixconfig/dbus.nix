{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.dconf.enable = true;
  services.dbus.enable = true;
}
