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
in
{
  home.packages = with pkgs; [
    hyprpicker
    hyprsunset
    hyprsysteminfo
    hyprpolkitagent
  ];
  services.swayosd.enable = true;
  services.swayosd.stylePath = null;
  services.swayosd.topMargin = 0.92;

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprlandPkg;

    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod, Q, exec, ghostty"
        "$mod, E, exec, nautilus"
        "$mod, C, killactive,"
        "$mod, W, exec, zen"
        # "$mod, M, exit,"
        "$mod, N, exec, swaync-client -t"
        "$mod, V, togglefloating,"

        # "$mod, A, exec, qs -c ii ipc call sidebarLeft toggle"
        # "$mod, Space, exec, qs -c ii ipc call search toggle"
        # "$mod SHIFT, T, global, quickshell:wallpaperSelectorToggle"
        # "$mod, t, exec, pkill waybar && waybar &"

        "$mod, SPACE, global, quickshell:appLauncher"
        "ALT, Space, exec, playerctl play-pause"

        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume,exec, swayosd-client --output-volume lower"
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        "CAPS, Caps_Lock, exec, swayosd-client --caps-lock"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"

        ", Print, exec, bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot -m region; fi'"
        "SHIFT, Print, exec, bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot -m window; fi'"

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

        "no_anim on, match:namespace quickshell:overview"
        "blur on, match:namespace quickshell:overview"
        "ignore_alpha 0.3, match:namespace quickshell:overview"
      ];

      windowrule = [
        "match:class showmethekey-gtk, float on"
        "match:class showmethekey-gtk, pin on"
        "match:class showmethekey-gtk, border_size 0"
        "match:class showmethekey-gtk, no_initial_focus on"

        "match:class brave-nngceckbapebfimnlniiiahkandclblb-Default, float on"
        "match:class brave-nngceckbapebfimnlniiiahkandclblb-Default, center on"

        "match:title ^Extension: \(Bitwarden Password Manager\).*, float on"
        "match:title ^Extension: \(Bitwarden Password Manager\).*, center on"

        "match:title ^Save File$, float on"
        "match:title ^Save File$, center on"
        "match:title .*wants to save$, float on"
        "match:title .*wants to save$, center on"

        "match:class rocketleague.exe, opacity 1.0 override 1.0 override 1.0 override"

        "match:title ^Calculator$, float on"
        "match:title ^Calculator$, center on"
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
        "qs -c learning &"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "blueman-applet"
        "swaync &"
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
        "rounding" = "2";
        "active_opacity" = "1";
        "inactive_opacity" = "1";
        "fullscreen_opacity" = "1";
      };

      dwindle = {
        "pseudotile" = "yes";
        "preserve_split" = "yes";
      };

      general = {
        "gaps_in" = "1";
        "gaps_out" = "4,-1,-2,-1";
        "border_size" = "2";
        "col.active_border" = "rgba(ddddddff)";
        "col.inactive_border" = "rgba(2c2c2cff)";
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

        "sensitivity" = "0";
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
          path = "~/wallpapers/1dbe9fe86f1517ba74b8c15c7990ed8f_upscaled_upscaled.jpg";
          fit_mode = "cover";
        }
      ];
    };
  };

}
