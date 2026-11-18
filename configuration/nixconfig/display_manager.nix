{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  quickshellPackage = import ../applications/quickshell/quickshell-package.nix {
    inherit pkgs;
    inherit (inputs) quickshell;
  };
  greeterConfigDir = ../applications/quickshell/config/minimal;
  greeterWallpaper = ../homemanagerconfig/wallpapers/cypberpunk.jpg;
  hyprlandSession = pkgs.writeShellScript "hyprland-session" ''
    hm_vars="/etc/profiles/per-user/''${USER:-$(id -un)}/etc/profile.d/hm-session-vars.sh"
    if [ -r "$hm_vars" ]; then
      . "$hm_vars"
    fi
    exec ${pkgs.systemd}/bin/systemd-cat -t hyprland-session \
      ${pkgs.hyprland}/bin/start-hyprland --path ${pkgs.hyprland}/bin/Hyprland
  '';
  greeterWallpaperPreload = pkgs.writeShellScript "greeter-wallpaper-preload" ''
    img="/var/cache/greeter-wallpaper/current"
    if [ ! -r "$img" ]; then
      img="${greeterWallpaper}"
    fi
    exec ${pkgs.swaybg}/bin/swaybg -i "$img" -m fill
  '';
  quickshellGreeter = pkgs.writeShellScriptBin "quickshell-greeter" ''
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR="1"
    export QUICKSHELL_GREETER_USER="aleks"
    if [ -r /var/cache/greeter-wallpaper/current ]; then
      export QUICKSHELL_GREETER_WALLPAPER="file:///var/cache/greeter-wallpaper/current"
    else
      export QUICKSHELL_GREETER_WALLPAPER="file://${greeterWallpaper}"
    fi
    export QUICKSHELL_GREETER_CMD="${hyprlandSession}"
    exec ${quickshellPackage}/bin/qs -p ${greeterConfigDir}/greeter.qml
  '';
  greeterHyprlandConfig = pkgs.writeText "hyprland-greeter.lua" ''
    hl.monitor({
      output = "",
      mode = "preferred",
      position = "auto",
      scale = 1,
    })

    hl.config({
      input = {
        kb_layout = "gb",
      },
      cursor = {
        no_hardware_cursors = 1,
      },
      misc = {
        background_color = "0x121212",
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
      },
      animations = {
        enabled = false,
      },
    })

    hl.on("hyprland.start", function()
      hl.exec_cmd("${greeterWallpaperPreload}")
      hl.exec_cmd("${quickshellGreeter}/bin/quickshell-greeter; ${pkgs.hyprland}/bin/hyprctl dispatch exit")
    end)
  '';
  greeterSession = pkgs.writeShellScript "greeter-session" ''
    export XCURSOR_THEME="Bibata-Modern-Classic"
    export XCURSOR_SIZE="24"
    export XCURSOR_PATH="${pkgs.bibata-cursors}/share/icons"
    exec ${pkgs.systemd}/bin/systemd-cat -t hyprland-greeter \
      ${pkgs.hyprland}/bin/start-hyprland --path ${pkgs.hyprland}/bin/Hyprland -- --config ${greeterHyprlandConfig}
  '';
in
{
  systemd = {
    tmpfiles.rules = [
      "d /var/cache/greeter-wallpaper 0755 aleks users -"
    ];

    services = {
      plymouth-quit = lib.mkIf config.boot.plymouth.enable {
        overrideStrategy = "asDropin";
        serviceConfig.ExecStart = [
          ""
          "-${pkgs.plymouth}/bin/plymouth quit --retain-splash"
        ];
      };

      greetd.serviceConfig.Type = lib.mkForce "simple";
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${greeterSession}";
        user = "greeter";
      };
    };
  };
}
