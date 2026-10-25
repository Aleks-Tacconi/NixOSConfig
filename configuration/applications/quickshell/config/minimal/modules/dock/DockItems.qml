pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "tray-apps.js" as TrayApps
import "../bar" as Bar
import "../../theme"

/** Scrollable dock row containing window groups, pins, and tray icons. */
Flickable {
    id: root

    required property var dataSource
    property var popupScreen: null
    property real popupRightMargin: Theme.gap * 2
    property real buttonSize: Theme.panelRowHeight - Theme.gap / 2
    property real spacing: Theme.gap
    property real hoverOverflow: Theme.gap
    readonly property real fullWidth: items.implicitWidth + root.hoverOverflow * 2
    readonly property int trayCount: tray.trayItems.length
    readonly property var trayEntries: SystemTray.items.values.map(item => ({
        item, desktopEntry: TrayApps.desktopEntryForTray(item, DesktopEntries.applications.values)
    }))
    readonly property var groups: root.dataSource.appGroups.map(group => ({
        appId: group.appId,
        pinned: group.pinned,
        active: group.active,
        toplevels: group.toplevels,
        tray: root.trayEntries.find(entry => TrayApps.matchesGroup(entry, group.appId,
            root.dataSource.desktopEntryForApp(group.appId))) ?? null
    }))
    readonly property var remainingTrayEntries: root.trayEntries.filter(entry =>
        !root.groups.some(group => group.tray === entry))
    signal popupRequested(var appGroup, var activator)
    signal trayMenuRequested

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: root.fullWidth
    contentHeight: height
    interactive: contentWidth > width

    /** Dismiss the tray menu before showing a window picker. */
    function closeTrayMenu() {
        tray.closeMenu();
    }

    Row {
        id: items

        x: root.hoverOverflow
        y: (root.height - height) / 2
        height: root.buttonSize
        spacing: root.spacing

        Repeater {
            model: root.groups

            DockAppButton {
                required property var modelData
                width: root.buttonSize
                height: root.buttonSize
                appGroup: modelData
                dataSource: root.dataSource
                trayItem: modelData.tray?.item ?? null
                onTrayMenuRequested: (item, activator) => tray.openMenu(item, activator)
                onPopupRequested: (appGroup, activator) => root.popupRequested(appGroup, activator)
            }
        }

        Bar.Tray {
            id: tray

            entries: root.remainingTrayEntries
            buttonSize: root.buttonSize
            popupScreen: root.popupScreen
            popupRightMargin: root.popupRightMargin
            onMenuRequested: root.trayMenuRequested()
        }
    }
}
