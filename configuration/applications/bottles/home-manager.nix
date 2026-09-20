{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.packages = [
    (pkgs.bottles.override {
      removeWarningPopup = true;
    })
  ];

  dconf.settings = {
    "com/usebottles/bottles" = {
      show-sandbox-warning = false;
    };
  };
}
