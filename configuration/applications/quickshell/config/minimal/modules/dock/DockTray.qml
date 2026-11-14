pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../theme"

/** Inline standalone tray icons for the dock, delegating menus to the unified dock popup. */
Row {
    id: root

    property real buttonSize: Theme.panelRowHeight - Theme.gap / 2
    property var entries: []
    property var activeTrayItem: null
    signal popupRequested(var entry, var activator)

    spacing: Theme.gap
    visible: root.entries.length > 0
    height: root.buttonSize

    Repeater {
        model: ScriptModel {
            values: root.entries
        }

        DockTrayButton {
            id: trayButton

            required property var modelData
            width: root.buttonSize
            height: root.buttonSize
            trayItem: trayButton.modelData.item
            desktopEntry: trayButton.modelData.desktopEntry
            menuOpen: root.activeTrayItem === trayButton.modelData.item
            onPopupRequested: activator => root.popupRequested(trayButton.modelData, activator)
        }
    }
}
