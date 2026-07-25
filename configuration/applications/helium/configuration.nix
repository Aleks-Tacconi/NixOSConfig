{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.helium-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.firefox
  ];
}
