pragma Singleton

import QtQuick

/**
 * Default shell configuration singleton, overridden at build time by Home Manager.
 */
QtObject {
    component LauncherConfig: QtObject {
        readonly property bool applications: true
        readonly property bool files: true
        readonly property bool emoji: true
        readonly property bool clipboard: true
        readonly property var enabledModes: ["applications", "files", "emoji", "clipboard"]
        readonly property var fileSearchPaths: []
        readonly property string configDir: ""
    }

    component WallpapersConfig: QtObject {
        readonly property string directory: ""
    }

    component NotificationsConfig: QtObject {
        readonly property int popupTimeout: 5000
        readonly property int queueLimit: 24
    }

    component NightLightConfig: QtObject {
        readonly property bool enable: true
        readonly property int temperature: 4200
    }

    component NetworkConfig: QtObject {
        readonly property bool tailscale: true
    }

    component AppMenuConfig: QtObject {
        readonly property bool enable: true
        readonly property bool nativeMenus: true
    }

    readonly property LauncherConfig launcher: LauncherConfig {}
    readonly property WallpapersConfig wallpapers: WallpapersConfig {}
    readonly property NotificationsConfig notifications: NotificationsConfig {}
    readonly property NightLightConfig nightLight: NightLightConfig {}
    readonly property NetworkConfig network: NetworkConfig {}
    readonly property AppMenuConfig appMenu: AppMenuConfig {}
}
