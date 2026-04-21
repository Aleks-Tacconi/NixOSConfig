{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
