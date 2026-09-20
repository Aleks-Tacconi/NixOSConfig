_:

{
  # Enable 32-bit graphics driver support required by Wine / 32-bit Windows applications
  hardware.graphics.enable32Bit = true;

  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
