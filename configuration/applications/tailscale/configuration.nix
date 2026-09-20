_:

{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=aleks" ];
  };
}
