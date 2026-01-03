{ config, pkgs, lib, inputs, ... }:

{
  services.syncthing = {
    enable = true;

    settings.gui = {
      user = "aleks";
      password = "asjhdfk,hoiyu2891`KJH!*(Yjkh2)";
    };

    settings.devices = {
      "laptop" = {
        id = "M4IEFYN-4IDLWXS-JEM2J7N-TONX3C2-FMOGHVC-SOZ64DV-X55KT3P-YCRFSAE";
      };
      "pc" = {
        id = "SFYMMDS-ZCGJO2Q-OZAFANZ-QWMN5JC-NPIUZFG-33NDATZ-B4ZTI4E-QE5ECAZ";
      };

      folders = {
        id = "1";
        "Sync" = {
          enable = true;
          path = "/home/aleks/Sync";
          devices = [ "laptop" "pc" ];
        };
      };
    };
  };
}
