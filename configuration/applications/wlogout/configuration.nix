_:

{
  home-manager = {
    users."aleks" = {
      imports = [ ./home-manager.nix ];
    };
  };
}
