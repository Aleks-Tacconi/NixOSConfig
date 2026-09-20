_:

{
  virtualisation.docker.enable = true;

  users.users.aleks.extraGroups = [
    "docker"
  ];
}
