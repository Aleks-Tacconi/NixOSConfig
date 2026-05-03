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
    # plugins = [ inputs.hyprland-plugins.packages.${system}.hyprbars ];

    settings = {
      "$mod" = "SUPER";

      # plugin = {
      #   hyprbars = {
      #     enabled = true;
      #     bar_height = 34;
      #     bar_blur = false;
      #     bar_color = "rgb(101010)";
      #     "col.text" = "rgb(f5f5f5)";
      #     bar_text_size = 12;
      #     bar_text_font = "Fira Sans Semibold";
      #     bar_text_align = "center";
      #     bar_buttons_alignment = "right";
      #     bar_part_of_window = true;
      #     bar_precedence_over_border = true;
      #     bar_padding = 10;
      #     bar_button_padding = 5;
      #     icon_on_hover = false;
      #     inactive_button_color = "rgb(101010)";
      #     on_double_click = "hyprctl dispatch fullscreen 1";
      #     "hyprbars-button" = [
      #       "rgb(121212), 28, 󰅖 , hyprctl dispatch killactive, rgb(ffffff)"
      #       "rgb(121212), 24, 󰹑 , hyprctl dispatch fullscreen 1, rgb(ffffff)"
      #       "rgb(121212), 27, 󰖯 , hyprctl dispatch togglefloating, rgb(ffffff)"
      #     ];
      #   };
      # };

      bind = [
        "$mod, Q, exec, ghostty"
        "$mod, E, exec, nautilus"
        "$mod, C, killactive,"
        "$mod, W, exec, zen"
        # "$mod, M, exit,"
        "$mod, N, exec, swaync-client -t"
        "$mod, A, exec, qs -c ii ipc call sidebarLeft toggle"
        "$mod, V, togglefloating,"
        "$mod, Space, exec, qs -c ii ipc call search toggle"
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

        "$mod, t, exec, pkill waybar && waybar &"
        "$mod SHIFT, T, global, quickshell:wallpaperSelectorToggle"
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
        ", Alt_L, global, quickshell:overviewAltReleaseClose"
        ", Alt_R, global, quickshell:overviewAltReleaseClose"

        "ALT, Tab, exec, bash ~/.config/hypr/hyprland/scripts/alt-tab-workspace.sh e+1"
        "ALT SHIFT, Tab, exec, bash ~/.config/hypr/hyprland/scripts/alt-tab-workspace.sh e-1"
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
        "match:title ^Calculator$, opacity 1.0 override 1.0 override 1.0 override"
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
        "qs -c ii &"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "waybar &"
        "blueman-applet"
        "swaync &"
        # "eww open random-window"
        # "bash /home/aleks/.config/eww/scripts/open_clock_all.sh"
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
        "inactive_opacity" = "0.95";
        "fullscreen_opacity" = "1";
      };

      dwindle = {
        "pseudotile" = "yes";
        "preserve_split" = "yes";
      };

      general = {
        "gaps_in" = "1";
        "gaps_out" = "5,0,0,0";
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

  # services.hyprpaper = {
  #   enable = true;
  #   settings = {
  #     splash = false;
  #     wallpaper = [
  #       {
  #         monitor = "";
  #         path = "~/wallpapers/wallpaper.png";
  #         fit_mode = "cover";
  #       }
  #     ];
  #   };
  # };

}
