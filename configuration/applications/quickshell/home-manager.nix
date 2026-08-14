{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}:

let
  cfg = osConfig.desktop.quickshell;
  launcherModes = lib.filter (mode: cfg.launcher.${mode}) [
    "applications"
    "files"
    "emoji"
    "clipboard"
  ];
  quickshellPackage = import ./quickshell-package.nix {
    inherit pkgs;
    inherit (inputs) quickshell;
  };
  gtkActionsPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.dbus-next ]);
  gtkActions = pkgs.writeShellApplication {
    name = "quickshell-gtk-actions";
    text = ''
      exec ${gtkActionsPython}/bin/python ${./gtk-actions.py} "$@"
    '';
  };
  qtMenu = pkgs.writeShellApplication {
    name = "quickshell-qt-menu";
    text = ''
      exec ${gtkActionsPython}/bin/python ${./qt-menu.py} "$@"
    '';
  };
  fileSearchPaths = pkgs.writeText "quickshell-file-search-paths" ''
    ${lib.concatStringsSep "\n" cfg.launcher.fileSearch.paths}
  '';
  fileSearchExcludes = pkgs.writeText "quickshell-file-search-excludes" ''
    ${lib.concatStringsSep "\n" cfg.launcher.fileSearch.excludes}
  '';
  configQml = pkgs.writeText "Config.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
        readonly property QtObject launcher: QtObject {
            readonly property bool applications: ${builtins.toJSON cfg.launcher.applications}
            readonly property bool files: ${builtins.toJSON cfg.launcher.files}
            readonly property bool emoji: ${builtins.toJSON cfg.launcher.emoji}
            readonly property bool clipboard: ${builtins.toJSON cfg.launcher.clipboard}
            readonly property var enabledModes: ${builtins.toJSON launcherModes}
        }

        readonly property QtObject notifications: QtObject {
            readonly property int popupTimeout: ${toString cfg.notifications.popupTimeout}
            readonly property int queueLimit: ${toString cfg.notifications.queueLimit}
        }

        readonly property QtObject nightLight: QtObject {
            readonly property bool enable: ${builtins.toJSON cfg.nightLight.enable}
            readonly property int temperature: ${toString cfg.nightLight.temperature}
        }

        readonly property QtObject network: QtObject {
            readonly property bool tailscale: ${builtins.toJSON cfg.network.tailscale}
        }

        readonly property QtObject appMenu: QtObject {
            readonly property bool enable: ${builtins.toJSON cfg.appMenu.enable}
            readonly property bool nativeMenus: ${builtins.toJSON cfg.appMenu.nativeMenus}
        }
    }
  '';
  configTree = pkgs.runCommand "quickshell-default-config" { } ''
    mkdir -p "$out"
    cp -r ${./config/minimal}/. "$out/"
    cp ${configQml} "$out/Config.qml"
    chmod u+w "$out/modules/launcher"
    cp ${fileSearchPaths} "$out/modules/launcher/whitelist.txt"
    cp ${fileSearchExcludes} "$out/modules/launcher/blacklist.txt"
  '';
in
{
  home.packages = [
    quickshellPackage
    gtkActions
    qtMenu
  ]
  ++ lib.optionals cfg.launcher.clipboard [ pkgs.cliphist ]
  ++ lib.optionals (cfg.launcher.clipboard || cfg.launcher.files || cfg.launcher.emoji) [
    pkgs.wl-clipboard
  ];

  xdg.configFile."quickshell/default".source = configTree;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = "QUICKSHELL_CONFIG_GENERATION=${configTree}";
      ExecStartPre = "-${quickshellPackage}/bin/qs kill --any-display -c minimal";
      ExecStart = "${quickshellPackage}/bin/qs";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.cleanupQuickshellConfigs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    config_dir="${config.xdg.configHome}/quickshell"
    if [ -d "$config_dir" ]; then
      for config_path in "$config_dir"/*; do
        [ -e "$config_path" ] || continue
        [ "''${config_path##*/}" = "default" ] || $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf "$config_path"
      done
    fi

    state_dir="${config.xdg.stateHome}/quickshell"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
      "$state_dir"
    if [ -f "$state_dir/minimal/dock-pins.json" ] && [ ! -e "$state_dir/dock-pins.json" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp \
        "$state_dir/minimal/dock-pins.json" "$state_dir/dock-pins.json"
    fi
  '';
}
