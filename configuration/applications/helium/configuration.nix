{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.systemPackages = [
    inputs.helium-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.google-chrome
    pkgs.firefox
  ];
}
