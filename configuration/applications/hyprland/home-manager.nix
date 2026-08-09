{
  config,
  pkgs,
  lib,
  inputs,
  osConfig,
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
    qs ipc --any-display call appLauncher open
  '';
  lua = lib.generators.mkLuaInline;
  mkBind = keys: dispatcher: {
    _args = [
      keys
      (lua dispatcher)
    ];
  };
  mkExecBind = keys: command: mkBind keys "hl.dsp.exec_cmd(${builtins.toJSON command})";
  mkMouseBind = keys: dispatcher: {
    _args = [
      keys
      (lua dispatcher)
      { mouse = true; }
    ];
  };
  modKey = key: lua ''mod .. " + ${key}"'';
  quickshellCfg = osConfig.desktop.quickshell;
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
    configType = "lua";
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
      mod._var = "SUPER";

      bind = [
        (mkExecBind (modKey "Q") "clean-run ghostty")
        (mkExecBind (modKey "E") "clean-run nautilus")
        (mkBind (modKey "C") "hl.dsp.window.close()")
        (mkExecBind (modKey "W") "clean-run google-chrome-stable")
        (mkExecBind (modKey "N") "clean-run qs ipc --any-display call notifications toggle")
        (mkBind (modKey "V") ''hl.dsp.window.float({ action = "toggle" })'')

        (mkExecBind (modKey "Space") "clean-run app-launcher")
        (mkExecBind "ALT + Space" "playerctl play-pause")

        (mkExecBind "XF86AudioRaiseVolume" "swayosd-client --output-volume raise")
        (mkExecBind "XF86AudioLowerVolume" "swayosd-client --output-volume lower")
        (mkExecBind "XF86AudioMute" "swayosd-client --output-volume mute-toggle")
        (mkExecBind "XF86AudioMicMute" "swayosd-client --input-volume mute-toggle")
        (mkExecBind "CAPS + Caps_Lock" "swayosd-client --caps-lock")
        (mkExecBind "XF86MonBrightnessUp" "swayosd-client --brightness raise")
        (mkExecBind "XF86MonBrightnessDown" "swayosd-client --brightness lower")

        (mkExecBind "Print" "clean-run bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot --silent -m region; fi'")
        (mkExecBind "SHIFT + Print" "clean-run bash -c 'if pgrep hyprshot > /dev/null; then pkill slurp; else hyprshot --silent -m window; fi'")

        (mkBind (modKey "h") ''hl.dsp.focus({ direction = "l" })'')
        (mkBind (modKey "l") ''hl.dsp.focus({ direction = "r" })'')
        (mkBind (modKey "k") ''hl.dsp.focus({ direction = "u" })'')
        (mkBind (modKey "j") ''hl.dsp.focus({ direction = "d" })'')
        (mkBind (modKey "SHIFT + H") ''hl.dsp.window.move({ direction = "l" })'')
        (mkBind (modKey "SHIFT + L") ''hl.dsp.window.move({ direction = "r" })'')
        (mkBind (modKey "SHIFT + K") ''hl.dsp.window.move({ direction = "u" })'')
        (mkBind (modKey "SHIFT + J") ''hl.dsp.window.move({ direction = "d" })'')
        (mkBind "ALT + L" "hl.dsp.window.resize({ x = 150, y = 0, relative = true })")
        (mkBind "ALT + H" "hl.dsp.window.resize({ x = -150, y = 0, relative = true })")
        (mkBind "ALT + k" "hl.dsp.window.resize({ x = 0, y = -150, relative = true })")
        (mkBind "ALT + J" "hl.dsp.window.resize({ x = 0, y = 150, relative = true })")
        (mkBind (modKey "F") "hl.dsp.window.fullscreen()")
        (mkBind (modKey "S") ''hl.dsp.workspace.toggle_special("magic")'')
        (mkBind (modKey "SHIFT + S") ''hl.dsp.window.move({ workspace = "special:magic" })'')
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            (mkBind (modKey "code:1${toString i}") "hl.dsp.focus({ workspace = ${toString ws} })")
            (mkBind (modKey "SHIFT + code:1${toString i}") "hl.dsp.window.move({ workspace = ${toString ws} })")
          ]
        ) 9
      ))
      ++ [
        (mkMouseBind (modKey "mouse:272") "hl.dsp.window.drag()")
        (mkMouseBind (modKey "mouse:273") "hl.dsp.window.resize()")
        (mkMouseBind (modKey "SHIFT + mouse:272") "hl.dsp.window.resize()")
      ];

      layer_rule = [
        {
          match.namespace = "selection";
          no_anim = true;
        }
        {
          match.namespace = "quickshell:topBar";
          blur = true;
        }
        {
          match.namespace = "quickshell:topBar";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:appMenuActions";
          blur = true;
        }
        {
          match.namespace = "quickshell:appMenuActions";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:appLauncher";
          blur = true;
        }
        {
          match.namespace = "quickshell:appLauncher";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:appLauncherPreview";
          blur = true;
        }
        {
          match.namespace = "quickshell:appLauncherPreview";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topLeftNotificationsPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topLeftNotificationsPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topLeftCalendarPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topLeftCalendarPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topLeftNotification";
          blur = true;
        }
        {
          match.namespace = "quickshell:topLeftNotification";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topRightAudioPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topRightAudioPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topRightNetworkPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topRightNetworkPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topRightBatteryPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topRightBatteryPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topBarDockPullout";
          blur = true;
        }
        {
          match.namespace = "quickshell:topBarDockPullout";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:topBarDockPullout";
          no_anim = true;
        }
        {
          match.namespace = "quickshell:powerMenu";
          blur = true;
        }
        {
          match.namespace = "quickshell:powerMenu";
          ignore_alpha = 0.05;
        }
        {
          match.namespace = "quickshell:overview";
          no_anim = true;
        }
        {
          match.namespace = "quickshell:overview";
          blur = true;
        }
        {
          match.namespace = "quickshell:overview";
          ignore_alpha = 0.3;
        }
      ];

      window_rule = [
        {
          match.class = "showmethekey-gtk";
          float = true;
        }
        {
          match.class = "showmethekey-gtk";
          pin = true;
        }
        {
          match.class = "showmethekey-gtk";
          border_size = 0;
        }
        {
          match.class = "showmethekey-gtk";
          no_initial_focus = true;
        }
        {
          match.title = "^Extension: (Bitwarden Password Manager).*";
          float = true;
        }
        {
          match.title = "^Extension: (Bitwarden Password Manager).*";
          center = true;
        }
        {
          match.title = "^Save File$";
          float = true;
        }
        {
          match.title = "^Save File$";
          center = true;
        }
        {
          match.title = ".*wants to save$";
          float = true;
        }
        {
          match.title = ".*wants to save$";
          center = true;
        }
      ];

      monitor = [
        {
          output = "HDMI-A-2";
          mode = "2560x1440@60";
          position = "auto";
          scale = 1;
        }
        {
          output = "eDP-1";
          mode = "1920x1200@60";
          position = "auto";
          scale = 1;
        }
      ];

      workspace_rule = [
        {
          workspace = "1";
          monitor = "eDP-1";
          default = true;
        }
        {
          workspace = "2";
          monitor = "eDP-1";
        }
        {
          workspace = "3";
          monitor = "eDP-1";
        }
        {
          workspace = "4";
          monitor = "eDP-1";
        }
        {
          workspace = "5";
          monitor = "eDP-1";
        }
        {
          workspace = "6";
          monitor = "eDP-1";
        }
        {
          workspace = "7";
          monitor = "HDMI-A-2";
          default = true;
        }
        {
          workspace = "8";
          monitor = "HDMI-A-2";
        }
        {
          workspace = "9";
          monitor = "HDMI-A-2";
        }
      ];

      config = {
        animations.enabled = true;

        cursor.no_hardware_cursors = 1;

        decoration = {
          rounding = 6;
          active_opacity = 1;
          inactive_opacity = 0.95;
          fullscreen_opacity = 1;
          dim_inactive = true;
          dim_strength = 0.08;
          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = true;
            xray = false;
            ignore_opacity = true;
          };
          shadow = {
            enabled = true;
            range = 10;
            render_power = 2;
            color = "rgba(00000070)";
            color_inactive = "rgba(00000045)";
          };
        };

        dwindle.preserve_split = true;

        general = {
          gaps_in = 1;
          gaps_out = 2;
          border_size = 2;
          col = {
            active_border = "rgba(f2f2f266)";
            inactive_border = "rgba(00000080)";
          };
          layout = "dwindle";
          allow_tearing = false;
          resize_on_border = true;
          extend_border_grab_area = 60;
          hover_icon_on_border = true;
          snap = {
            enabled = true;
            window_gap = 10;
          };
        };

        input = {
          kb_layout = "gb";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            scroll_factor = 0.15;
          };
          sensitivity = 0.1;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          focus_on_activate = true;
        };
      };

      curve._args = [
        "soft"
        {
          type = "bezier";
          points = [
            [
              0.18
              1.0
            ]
            [
              0.3
              1.0
            ]
          ];
        }
      ];

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 2;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 2;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 3;
          bezier = "soft";
          style = "slide 12%";
        }
        {
          leaf = "workspacesOut";
          enabled = false;
        }
        {
          leaf = "workspacesIn";
          enabled = true;
          speed = 3;
          bezier = "soft";
          style = "slide 12%";
        }
        {
          leaf = "specialWorkspace";
          enabled = true;
          speed = 3;
          bezier = "soft";
          style = "slidevert 20%";
        }
      ];

    };

    extraConfig = ''
      hl.on("hyprland.start", function()
        ${lib.optionalString (quickshellCfg.enable && quickshellCfg.launcher.clipboard) ''
          hl.exec_cmd("clean-run wl-paste --type text --watch cliphist store")
          hl.exec_cmd("clean-run wl-paste --type image --watch cliphist store")
        ''}
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
        hl.exec_cmd("clean-run blueman-applet")
        hl.exec_cmd("hyprlock")
      end)
    '';

  };

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = "~/.hyprland-assets/wallpaper.jpg";
          fit_mode = "cover";
        }
      ];
    };
  };

}
