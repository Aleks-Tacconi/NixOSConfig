pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../frame" as Frame
import "../../theme"

/**
 * Organized actions and window previews for one dock application.
 */
ColumnLayout {
    id: root

    required property var appGroup
    required property var dataSource
    property bool previewsActive: false

    readonly property string appId: root.appGroup?.appId ?? ""
    readonly property string appName: root.dataSource.appNameForApp(root.appId)
    readonly property int windowCount: root.appGroup?.toplevels?.length ?? 0
    readonly property bool pinned: root.dataSource.isPinned(root.appId)
    readonly property bool canLaunch: root.dataSource.desktopEntryForApp(root.appId) !== null
    readonly property string iconSource: root.dataSource.iconSourceForApp(root.appId)
    readonly property var desktopActions: root.dataSource.desktopActionsForApp(root.appId)

    signal dismissRequested

    spacing: Theme.panelItemGap

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.gap * 3

        IconImage {
            visible: root.iconSource.length > 0
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            source: root.iconSource
        }

        Rectangle {
            visible: root.iconSource.length === 0
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Theme.surfaceRadius
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: root.appName.slice(0, 1).toUpperCase()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                font.bold: true
            }
        }

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: root.appName
            detail: root.windowCount > 0 ? String(root.windowCount) : ""
            primary: true
        }
    }

    Frame.PanelSectionHeader {
        Layout.fillWidth: true
        title: "Actions"
    }

    Frame.PanelActionRow {
        visible: root.canLaunch
        Layout.fillWidth: true
        label: root.windowCount > 0 ? "New window" : "Open"
        icon: "󰐕"
        showTrailing: false
        onClicked: {
            root.dataSource.launchApp(root.appId);
            root.dismissRequested();
        }
    }

    Repeater {
        model: root.desktopActions

        Frame.PanelActionRow {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            icon: "󰘳"
            showTrailing: false
            onClicked: {
                modelData.execute();
                root.dismissRequested();
            }
        }
    }

    Frame.PanelActionRow {
        Layout.fillWidth: true
        label: root.pinned ? "Unpin from dock" : "Pin to dock"
        icon: root.pinned ? "󰐃" : "󰐂"
        active: root.pinned
        enabled: root.pinned || root.canLaunch
        showTrailing: false
        onClicked: {
            root.dataSource.togglePinned(root.appId);
            root.dismissRequested();
        }
    }

    Frame.PanelSectionHeader {
        visible: root.windowCount > 0
        Layout.fillWidth: true
        title: "Windows"
        detail: String(root.windowCount)
    }

    Column {
        id: windowsColumn

        visible: root.windowCount > 0
        Layout.fillWidth: true
        spacing: Theme.panelItemGap

        Repeater {
            model: root.appGroup?.toplevels ?? []

            DockWindowRow {
                required property var modelData

                width: windowsColumn.width
                dataSource: root.dataSource
                toplevel: modelData
                previewsActive: root.previewsActive
                onActivated: root.dismissRequested()
            }
        }
    }
}
