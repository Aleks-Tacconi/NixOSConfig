{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
      timeout = 10;
      efi.canTouchEfiVariables = true;
    };
  };
}
