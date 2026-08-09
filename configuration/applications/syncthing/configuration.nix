_:

{
  services.syncthing = {
    enable = true;
    user = "aleks";
    dataDir = "/home/aleks";
    configDir = "/home/aleks/.config/syncthing";
    openDefaultPorts = true;
  };
}
