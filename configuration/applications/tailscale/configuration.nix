{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{

  # https://tailscale.com
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  networking.firewall = {
    allowedTCPPorts = [ 8096 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
