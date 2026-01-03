{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/home/aleks/Media";
    user = "aleks";
  };
}
