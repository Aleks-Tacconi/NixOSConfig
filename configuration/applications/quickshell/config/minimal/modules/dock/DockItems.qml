pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "tray-apps.js" as TrayApps
import "../../theme"

/** Scrollable dock row containing window groups, pins, and tray icons. */
Flickable {
    id: root

    required property var dataSource
    property real buttonSize: Theme.panelRowHeight - Theme.gap / 2
    property real spacing: Theme.gap
    property real hoverOverflow: Theme.gap
    property string activeGroupKey: ""
    property var activeTrayItem: null
    readonly property real fullWidth: items.implicitWidth + root.hoverOverflow * 2
    readonly property int trayCount: SystemTray.items.values.length
    readonly property var trayEntries: SystemTray.items.values.map(item => ({
        item: item,
        desktopEntry: TrayApps.desktopEntryForTray(item, DesktopEntries.applications.values)
    }))
    readonly property var groups: root.dataSource.appGroups.map(group => {
        const desktopEntry = root.dataSource.desktopEntryForApp(group.appId);
        const tray = root.trayEntries.find(entry => TrayApps.matchesGroup(entry, group.appId, desktopEntry)) ?? null;
        return {
            appId: group.appId,
            pinned: group.pinned,
            active: group.active,
            toplevels: group.toplevels,
            tray: tray,
            desktopEntry: desktopEntry ?? tray?.desktopEntry ?? null
        };
    })
    readonly property var remainingTrayEntries: root.trayEntries.filter(entry =>
        !root.groups.some(group => group.tray === entry))
    signal popupRequested(var appGroup, var activator)

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: root.fullWidth
    contentHeight: height
    interactive: contentWidth > width

    function trayGroupForEntry(entry) {
        const appId = entry?.desktopEntry?.id ?? "";
        return {
            appId: appId,
            pinned: appId.length > 0 ? root.dataSource.isPinned(appId) : false,
            active: false,
            toplevels: [],
            tray: entry,
            desktopEntry: entry?.desktopEntry ?? null
        };
    }

    Row {
        id: items

        x: root.hoverOverflow
        y: (root.height - height) / 2
        height: root.buttonSize
        spacing: root.spacing

        Repeater {
            model: ScriptModel {
                values: root.groups
            }

            DockAppButton {
                id: appButton

                required property var modelData
                width: root.buttonSize
                height: root.buttonSize
                appGroup: appButton.modelData
                dataSource: root.dataSource
                trayItem: appButton.modelData.tray?.item ?? null
                menuOpen: root.activeGroupKey.length > 0
                    && root.dataSource.normalizedAppId(appButton.modelData.appId) === root.activeGroupKey
                onPopupRequested: (appGroup, activator) => root.popupRequested(appGroup, activator)
            }
        }

        DockTray {
            id: tray

            entries: root.remainingTrayEntries
            buttonSize: root.buttonSize
            activeTrayItem: root.activeTrayItem
            onPopupRequested: (entry, activator) => root.popupRequested(root.trayGroupForEntry(entry), activator)
        }
    }
}
