{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  users.groups.media = { };
  users.users.aleks = {
    isNormalUser = true;
    description = "Aleksander Tacconi";
    extraGroups = [
      "networkmanager"
      "wheel"
      "power"
      "input"
      "plugdev"
      "media"
      "jellyfin"
    ];
    shell = pkgs.zsh;
  };
  hardware.uinput.enable = true;
}
