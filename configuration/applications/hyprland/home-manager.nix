{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
  cleanRun = pkgs.writeShellScriptBin "clean-run" ''
    exec ${pkgs.util-linux}/bin/setpriv --inh-caps=-all --ambient-caps=-all "$@"
  '';
  appLauncher = pkgs.writeShellScriptBin "app-launcher" ''
    monitor="$(${hyprlandPkg}/bin/hyprctl -j monitors | ${pkgs.jq}/bin/jq -r 'first(.[] | select(.focused)) | "\(.x) \(.y) \(.width) \(.height)"')"
    read -r x y width height <<EOF
    $monitor
    EOF

    center_x=$((x + width / 2))
    center_y=$((y + height / 2))

    ${hyprlandPkg}/bin/hyprctl dispatch movecursor "$center_x" "$center_y"
    qs -c minimal ipc --any-display call appLauncher open
  '';
in
{
  home.packages = with pkgs; [
    appLauncher
    cleanRun
    hyprpicker
    hyprsunset
    hyprsysteminfo
    hyprpolkitagent
  ];
  services.swayosd = {
    enable = true;
    stylePath = null;
    topMargin = 0.92;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandPkg;
    configType = "hyprlang";
    systemd = {
      enable = true;
      variables = [
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_DESKTOP"
      ];
    };

    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod, Q, exec, clean-run ghostty"
        "$mod, E, exec, clean-run nautilus"
        "$mod, C, killactive,"
        "$mod, W, exec, clean-run google-chrome-stable"
        # "$mod, M, exit,"
        "$mod, N, exec, clean-run qs -c minimal ipc --any-display call notifications toggle"
        "$mod, V, togglefloating,"

        "$mod, Space, exec, clean-run app-launcher"
        "ALT, Space, exec, playerctl play-pause"

        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume,exec, swayosd-client --output-volume lower"
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        "CAPS, Caps_Lock, exec, swayosd-client --caps-lock"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"

        ", Print, exec, clean-run bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot -m region; fi'"
        "SHIFT, Print, exec, clean-run bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot -m window; fi'"

        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        "ALT, L, resizeactive, 150 0"
        "ALT, H, resizeactive, -150 0"
        "ALT, k, resizeactive, 0 -150"
        "ALT, J, resizeactive, 0 150"
        "$mod,F,fullscreen"
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]

        ) 9
      ));

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod SHIFT, mouse:272, resizewindow"
      ];

      bindr = [ ];

      misc = {
        "force_default_wallpaper" = "0";
        "disable_hyprland_logo" = "true";
        "focus_on_activate" = "true";
      };

      layerrule = [
        "no_anim on, match:namespace selection"

        "blur on, match:namespace quickshell:topBar"
        "ignore_alpha 0.05, match:namespace quickshell:topBar"
        "blur on, match:namespace quickshell:appLauncher"
        "ignore_alpha 0.05, match:namespace quickshell:appLauncher"
        "blur on, match:namespace quickshell:appLauncherPreview"
        "ignore_alpha 0.05, match:namespace quickshell:appLauncherPreview"
        "blur on, match:namespace quickshell:topLeftNotificationsPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topLeftNotificationsPullout"
        "blur on, match:namespace quickshell:topLeftCalendarPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topLeftCalendarPullout"
        "blur on, match:namespace quickshell:topLeftNotification"
        "ignore_alpha 0.05, match:namespace quickshell:topLeftNotification"
        "blur on, match:namespace quickshell:topRightAudioPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topRightAudioPullout"
        "blur on, match:namespace quickshell:topRightNetworkPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topRightNetworkPullout"
        "blur on, match:namespace quickshell:topRightBatteryPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topRightBatteryPullout"
        "blur on, match:namespace quickshell:topBarDockPullout"
        "ignore_alpha 0.05, match:namespace quickshell:topBarDockPullout"
        "no_anim on, match:namespace quickshell:topBarDockPullout"
        "blur on, match:namespace quickshell:powerMenu"
        "ignore_alpha 0.05, match:namespace quickshell:powerMenu"

        "no_anim on, match:namespace quickshell:overview"
        "blur on, match:namespace quickshell:overview"
        "ignore_alpha 0.3, match:namespace quickshell:overview"
      ];

      windowrule = [
        "match:class showmethekey-gtk, float on"
        "match:class showmethekey-gtk, pin on"
        "match:class showmethekey-gtk, border_size 0"
        "match:class showmethekey-gtk, no_initial_focus on"

        "match:title ^Extension: \(Bitwarden Password Manager\).*, float on"
        "match:title ^Extension: \(Bitwarden Password Manager\).*, center on"

        "match:title ^Save File$, float on"
        "match:title ^Save File$, center on"
        "match:title .*wants to save$, float on"
        "match:title .*wants to save$, center on"

      ];
      # ... , mirror, eDP-1

      monitor = [
        "HDMI-A-2, 2560x1440@60, auto, 1"
        "eDP-1,1920x1200@60,auto,1"
        # ", preferred, auto, 1, mirror, eDP-1"
      ];

      workspace = [
        "1, monitor:eDP-1, default:true"
        "2, monitor:eDP-1"
        "3, monitor:eDP-1"
        "4, monitor:eDP-1"
        "5, monitor:eDP-1"
        "6, monitor:eDP-1"
        "7, monitor:HDMI-A-2, default:true"
        "8, monitor:HDMI-A-2"
        "9, monitor:HDMI-A-2"
      ];

      cursor = {
        "no_hardware_cursors" = "true";
      };

      exec = [ ];
      exec-once = [
        "clean-run wl-paste --type text --watch cliphist store"
        "clean-run wl-paste --type image --watch cliphist store"
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "clean-run blueman-applet"
        "hyprlock"
      ];

      animations = {
        "enabled" = "true";

        bezier = [
          "soft, 0.18, 1.0, 0.3, 1.0"
        ];

        animation = [
          "windows, 1, 2, default"
          "fade, 1, 2, default"
          "workspaces, 1, 3, soft, slide 12%"
          "workspacesOut, 0"
          "workspacesIn, 1, 3, soft, slide 12%"
          "specialWorkspace, 1, 3, soft, slidevert 20%"
        ];
      };

      decoration = {
        "rounding" = "6";
        "active_opacity" = "1";
        "inactive_opacity" = "0.95";
        "fullscreen_opacity" = "1";
        "dim_inactive" = "true";
        "dim_strength" = "0.08";
        blur = {
          "enabled" = "true";
          "size" = "8";
          "passes" = "3";
          "new_optimizations" = "true";
          "xray" = "false";
          "ignore_opacity" = "true";
        };
        shadow = {
          "enabled" = "true";
          "range" = "10";
          "render_power" = "2";
          "color" = "rgba(00000070)";
          "color_inactive" = "rgba(00000045)";
        };
      };

      dwindle = {
        "pseudotile" = "yes";
        "preserve_split" = "yes";
      };

      general = {
        "gaps_in" = "1";
        # Top, Right, Bottom, Left
        # cypberpunk gaps: "gaps_out" = "4,-2,-3,-2";
        "gaps_out" = "2,2,2,2";
        "border_size" = "2";
        "col.active_border" = "rgba(f2f2f266)";
        "col.inactive_border" = "rgba(00000080)";
        "layout" = "dwindle";
        "allow_tearing" = "false";
        "resize_on_border" = "true";
        "extend_border_grab_area" = "60";
        "hover_icon_on_border" = "true";
        snap = {
          "enabled" = "true";
          "window_gap" = "10";
        };
      };

      input = {
        "kb_layout" = "gb";
        "kb_variant" = "";
        "kb_model" = "";
        "kb_options" = "";
        "kb_rules" = "";

        "follow_mouse" = "1";

        touchpad = {
          "natural_scroll" = "true";
          "disable_while_typing" = "true";
          "scroll_factor" = "0.15";
        };

        "sensitivity" = "0.1";
      };
    };

  };

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "~/wallpapers/moon.jpg";
          fit_mode = "cover";
        }
      ];
    };
  };

}
