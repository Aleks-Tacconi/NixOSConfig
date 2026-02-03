{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  programs.npm.enable = true;
  environment.systemPackages = with pkgs; [
  ];

}
