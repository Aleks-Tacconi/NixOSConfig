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
  launcherFileSearchPaths = map (
    path:
    if lib.hasPrefix "/" path then
      path
    else if lib.hasPrefix "~/" path then
      "${config.home.homeDirectory}/${lib.removePrefix "~/" path}"
    else
      "${config.home.homeDirectory}/${path}"
  ) cfg.launcher.fileSearch.paths;
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
  networkControl = pkgs.writeShellApplication {
    name = "quickshell-network-control";
    runtimeInputs = [ pkgs.networkmanager ];
    text = ''
      exec ${pkgs.python3}/bin/python ${./network_control.py} "$@"
    '';
  };
  fileSearchPaths = pkgs.writeText "quickshell-file-search-paths" ''
    ${lib.concatStringsSep "\n" cfg.launcher.fileSearch.paths}
  '';
  fileSearchExcludes = pkgs.writeText "quickshell-file-search-excludes" ''
    ${lib.concatStringsSep "\n" cfg.launcher.fileSearch.excludes}
  '';
  fileSearch = pkgs.writeShellApplication {
    name = "quickshell-file-search";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
      pkgs.fzf
    ];
    text = ''
      query="''${1:-''${FILE_QUERY:-}}"
      selected_dir="''${2:-''${FILE_DIR:-}}"
      whitelist="''${FILE_WHITELIST:-${fileSearchPaths}}"
      blacklist="''${FILE_BLACKLIST:-${fileSearchExcludes}}"
      home="''${HOME:-${config.home.homeDirectory}}"

      dirs=()
      while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
          /*) dir="$line" ;;
          ~/*) dir="$home/''${line#\~/}" ;;
          *) dir="$home/$line" ;;
        esac
        [ -d "$dir" ] && dirs+=("$dir")
      done < "$whitelist"

      if [ -z "$selected_dir" ]; then
        [ "''${#dirs[@]}" -eq 0 ] && exit 0
        printf 'directory\t%s\0' "''${dirs[@]}" | fzf --read0 --print0 --filter "$query" || true
        exit 0
      fi

      excludes=()
      while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        excludes+=(--exclude "$line")
      done < "$blacklist"

      {
        fd --type f --color never --absolute-path --print0 "''${excludes[@]}" . "$selected_dir" 2>/dev/null \
          | fzf --read0 --print0 --filter "$query" \
          | {
              count=0
              while IFS= read -r -d ''' path; do
                printf 'file\t%s\0' "$path"
                count=$((count + 1))
                [ "$count" -lt 80 ] || break
              done
            }
      } || true
    '';
  };
  configQml = pkgs.writeText "Config.qml" ''
    pragma Singleton

    import QtQuick

    QtObject {
        component LauncherConfig: QtObject {
            readonly property bool applications: ${builtins.toJSON cfg.launcher.applications}
            readonly property bool files: ${builtins.toJSON cfg.launcher.files}
            readonly property bool emoji: ${builtins.toJSON cfg.launcher.emoji}
            readonly property bool clipboard: ${builtins.toJSON cfg.launcher.clipboard}
            readonly property var enabledModes: ${builtins.toJSON launcherModes}
            readonly property var fileSearchPaths: ${builtins.toJSON launcherFileSearchPaths}
            readonly property string configDir: ${builtins.toJSON "${config.xdg.configHome}/quickshell/default/modules/launcher"}
        }

        component WallpapersConfig: QtObject {
            readonly property string directory: ${builtins.toJSON "file://${config.home.homeDirectory}/.local/share/wallpapers"}
        }

        component NotificationsConfig: QtObject {
            readonly property int popupTimeout: ${toString cfg.notifications.popupTimeout}
            readonly property int queueLimit: ${toString cfg.notifications.queueLimit}
        }

        component NightLightConfig: QtObject {
            readonly property bool enable: ${builtins.toJSON cfg.nightLight.enable}
            readonly property int temperature: ${toString cfg.nightLight.temperature}
        }

        component NetworkConfig: QtObject {
            readonly property bool tailscale: ${builtins.toJSON cfg.network.tailscale}
        }

        component AppMenuConfig: QtObject {
            readonly property bool enable: ${builtins.toJSON cfg.appMenu.enable}
            readonly property bool nativeMenus: ${builtins.toJSON cfg.appMenu.nativeMenus}
        }

        readonly property LauncherConfig launcher: LauncherConfig {}
        readonly property WallpapersConfig wallpapers: WallpapersConfig {}
        readonly property NotificationsConfig notifications: NotificationsConfig {}
        readonly property NightLightConfig nightLight: NightLightConfig {}
        readonly property NetworkConfig network: NetworkConfig {}
        readonly property AppMenuConfig appMenu: AppMenuConfig {}
    }
  '';
  configTree = pkgs.runCommand "quickshell-default-config" { } ''
    mkdir -p "$out"
    cp -r ${./config/minimal}/. "$out/"
    chmod -R u+w "$out"
    cp ${configQml} "$out/Config.qml"
    cp ${fileSearchPaths} "$out/modules/launcher/whitelist.txt"
    cp ${fileSearchExcludes} "$out/modules/launcher/blacklist.txt"
  '';
in
{
  home.packages = [
    quickshellPackage
    gtkActions
    qtMenu
    networkControl
    fileSearch
    pkgs.xdg-utils
  ]
  ++ lib.optionals cfg.launcher.clipboard [ pkgs.cliphist ]
  ++ lib.optionals cfg.launcher.files [
    pkgs.fd
    pkgs.fzf
  ]
  ++ lib.optionals (cfg.launcher.clipboard || cfg.launcher.files || cfg.launcher.emoji) [
    pkgs.wl-clipboard
  ];

  xdg.configFile."quickshell/default".source = configTree;
  xdg.dataFile."wallpapers".source = ../../homemanagerconfig/wallpapers;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Environment = "QUICKSHELL_CONFIG_GENERATION=${configTree}";
      ExecStart = "${quickshellPackage}/bin/qs";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.ensureQuickshellStateDir = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.xdg.stateHome}/quickshell"
  '';
}
