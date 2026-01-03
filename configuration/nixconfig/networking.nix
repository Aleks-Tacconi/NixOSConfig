{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  networking = {
    hostName = "aleks";

    wireless = {
      enable = false;
      iwd.enable = false;
    };

    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
      };
    };

    firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPorts = [ 41641 ];
    };
  };

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];
}
