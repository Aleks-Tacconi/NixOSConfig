{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # services.ollama.enable = true;

  home-manager.users."aleks".home.sessionVariables = {
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    LD_LIBRARY_PATH = lib.mkForce "${pkgs.libglvnd}/lib:${pkgs.gcc.cc.lib}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
  };

  home-manager.users."aleks".home.activation.forceAndroidEmulatorGpuHost =
    inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
      ''
        AVD_DIR="/home/aleks/.android/avd"

        if [ -d "$AVD_DIR" ]; then
          for cfg in "$AVD_DIR"/*.avd/config.ini; do
            [ -f "$cfg" ] || continue

            if ${pkgs.gnugrep}/bin/grep -q '^hw\.gpu\.enabled=' "$cfg"; then
              $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^hw\.gpu\.enabled=.*/hw.gpu.enabled=yes/' "$cfg"
            else
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf 'hw.gpu.enabled=yes\n' >> "$cfg"
            fi

            if ${pkgs.gnugrep}/bin/grep -q '^hw\.gpu\.mode=' "$cfg"; then
              $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^hw\.gpu\.mode=.*/hw.gpu.mode=host/' "$cfg"
            else
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf 'hw.gpu.mode=host\n' >> "$cfg"
            fi
          done
        fi
      '';

  home-manager.users."aleks".wayland.windowManager.hyprland.settings = {
    monitor = lib.mkForce [
      "eDP-1, 1920x1200@60, 0x0, 1"
      "DP-1, 1920x1080@60, -1920x0, 1"
    ];

    workspace = lib.mkForce [
      "1, monitor:eDP-1, default:true"
      "2, monitor:eDP-1"
      "3, monitor:eDP-1"
      "4, monitor:eDP-1"
      "5, monitor:eDP-1"
      "6, monitor:eDP-1"
      "7, monitor:DP-1, default:true"
      "8, monitor:DP-1"
      "9, monitor:DP-1"
    ];
  };

  imports = [
    ./core.nix
    ./hardware-configuration-laptop.nix
    ../configuration/applications/eww/configuration-laptop.nix
    ../configuration/nixconfig/bluetooth.nix
    ../configuration/applications/emulator/configuration.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/tpacpi::kbd_backlight/brightness - - - - 2" ];
}
