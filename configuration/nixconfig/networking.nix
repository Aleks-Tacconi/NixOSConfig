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

    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;
        backend = "wpa_supplicant";
      };
    };

    firewall = {
      allowedTCPPorts = [ 6543 ];
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
