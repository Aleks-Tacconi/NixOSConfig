{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
