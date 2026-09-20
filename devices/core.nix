{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
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
    # ../configuration/applications/jellyfin/configuration.nix
    # ../configuration/applications/emulator/configuration.nix
    # ../configuration/applications/android/configuration.nix
    ../configuration/applications/obsstudio/configuration.nix
    ../configuration/applications/agents/configuration.nix
    ../configuration/applications/docker/configuration.nix
    ../configuration/applications/tailscale/configuration.nix
    ../configuration/applications/chrome/configuration.nix
    ../configuration/applications/gdrive/configuration.nix
    ../configuration/applications/firefox/configuration.nix
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
    ../configuration/applications/qbittorrent/configuration.nix
    ../configuration/applications/syncthing/configuration.nix
    ../configuration/applications/tmux/configuration.nix
    ../configuration/applications/bottles/configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "25.05";
}
