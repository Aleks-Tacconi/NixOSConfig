{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  virtualisation.docker.enable = true;

  services.tailscale.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  users.users.aleks.extraGroups = [
    "docker"
    "wireshark"
  ];

  hardware.enableAllFirmware = true;
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users."aleks" = {
      imports = [ ../home.nix ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    antigravity-cli
  ];

  programs.xwayland.enable = true;

  imports = [
    inputs.home-manager.nixosModules.default

    ../configuration/nixconfig/boot.nix
    ../configuration/nixconfig/nixpkgs.nix
    ../configuration/nixconfig/networking.nix
    ../configuration/nixconfig/locale.nix
    ../configuration/nixconfig/keyboard.nix
    ../configuration/nixconfig/pipewire.nix
    ../configuration/nixconfig/dbus.nix
    ../configuration/nixconfig/display_manager.nix
    ../configuration/nixconfig/ssh.nix
    ../configuration/nixconfig/security.nix
    ../configuration/nixconfig/npm.nix
    ../configuration/nixconfig/fonts.nix
    ../configuration/nixconfig/users.nix

    # applications
    ../configuration/applications/opencode/configuration.nix
    ../configuration/applications/chrome/configuration.nix
    ../configuration/applications/gdrive/configuration.nix
    ../configuration/applications/helium/configuration.nix
    ../configuration/applications/jellyfin/configuration.nix
    ../configuration/applications/discord/configuration.nix
    ../configuration/applications/eza/configuration.nix
    ../configuration/applications/audiocontrol/configuration.nix
    ../configuration/applications/filemanager/configuration.nix
    ../configuration/applications/hyprland/configuration.nix
    ../configuration/applications/hyprlock/configuration.nix
    ../configuration/applications/kdeconnect/configuration.nix
    ../configuration/applications/quickshell/configuration.nix
    ../configuration/applications/terminal-utils/configuration.nix
    ../configuration/applications/ghostty/configuration.nix
    ../configuration/applications/libreoffice/configuration.nix
    ../configuration/applications/mediaplayer/configuration.nix
    ../configuration/applications/nvim/configuration.nix
    ../configuration/applications/obsidian/configuration.nix
    ../configuration/applications/obsstudio/configuration.nix
    ../configuration/applications/qbittorrent/configuration.nix
    ../configuration/applications/spotify/configuration.nix
    ../configuration/applications/syncthing/configuration.nix
    ../configuration/applications/tmux/configuration.nix
    ../configuration/applications/wlogout/configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "25.05";
}
