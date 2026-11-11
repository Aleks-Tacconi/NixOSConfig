{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  vial = pkgs.vial.override {
    appimageTools = pkgs.appimageTools // {
      wrapType2 =
        args:
        pkgs.appimageTools.wrapType2 (
          args
          // {
            extraPkgs = pkgs: [ pkgs.libgpg-error ];
          }
        );
    };
  };
in
{
  home.packages = [
    vial
    pkgs.qmk
  ];
}
