{ config, pkgs, inputs, lib, ... }:

{
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
}
