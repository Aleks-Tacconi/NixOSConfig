pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../frame" as Frame
import "../../theme"

/**
 * Unified dock panel with header actions, tabbed options, and window previews.
 */
ColumnLayout {
    id: root

    required property var appGroup
    required property var dataSource
    property bool previewsActive: false
    property real maxBodyHeight: 440
    property string activeTab: "options"
    property string lastAppKey: ""

    readonly property string appId: root.appGroup?.appId ?? ""
    readonly property var desktopEntry: root.dataSource.desktopEntryForGroup(root.appGroup)
    readonly property var trayItem: root.appGroup?.tray?.item ?? null
    readonly property string appName: root.dataSource.appNameForGroup(root.appGroup)
    readonly property string iconSource: root.dataSource.iconSourceForGroup(root.appGroup)
    readonly property int windowCount: root.appGroup?.toplevels?.length ?? 0
    readonly property bool pinned: root.dataSource.isPinned(root.appId)
    readonly property bool canLaunch: root.desktopEntry !== null
    readonly property bool canActivateTray: root.trayItem !== null && !root.trayItem.onlyMenu
    readonly property bool canOpen: root.canLaunch || root.canActivateTray
    readonly property bool canPin: root.appId.length > 0 && (root.pinned || root.canLaunch)
    readonly property var desktopActions: root.dataSource.desktopActionsForGroup(root.appGroup)
    readonly property var appMenu: root.dataSource.menuForGroup(root.appGroup)
    readonly property var gtkActions: root.appMenu === null ? root.dataSource.gtkActionsForGroup(root.appGroup) : []
    readonly property bool hasOptions: root.appMenu !== null || root.gtkActions.length > 0 || root.desktopActions.length > 0
    readonly property bool hasBoth: root.hasOptions && root.windowCount > 0
    readonly property bool showOptions: root.hasOptions && (!root.hasBoth || root.activeTab === "options")
    readonly property bool showWindows: root.windowCount > 0 && (!root.hasBoth || root.activeTab === "windows")

    signal dismissRequested

    component HeaderIconButton: Rectangle {
        id: iconBtn
        required property string icon
        property bool active: false
        signal clicked
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: Theme.surfaceRadius
        color: btnMouse.containsMouse || iconBtn.active ? Theme.panelSurfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: iconBtn.icon
            color: iconBtn.active || btnMouse.containsMouse ? Theme.fg : Theme.muted
            font { family: Theme.iconFontFamily; pixelSize: Theme.iconSize }
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconBtn.clicked()
        }
    }

    component TabChip: Rectangle {
        id: chip
        required property string label
        required property bool selected
        signal clicked
        Layout.fillWidth: true
        Layout.preferredHeight: 26
        radius: Theme.surfaceRadius
        color: chip.selected ? Theme.panelSurfaceHover : (chipMouse.containsMouse ? Theme.panelSurface : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected || chipMouse.containsMouse ? Theme.fg : Theme.muted
            font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize; weight: chip.selected ? Theme.emphasisWeight : Font.Normal }
        }
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    spacing: Theme.panelItemGap
    onAppGroupChanged: {
        const key = `${root.appId}|${root.trayItem?.id ?? ""}`;
        if (key !== root.lastAppKey) {
            root.lastAppKey = key;
            root.activeTab = "options";
        }
        if (root.appMenu === null)
            root.dataSource.ensureGtkActionsForGroup(root.appGroup);
    }
    function resetMenu() { menuView.reset(); }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.gap * 2

        IconImage {
            visible: root.iconSource.length > 0
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            source: root.iconSource
        }

        Frame.PanelSectionHeader { Layout.fillWidth: true; title: root.appName }

        HeaderIconButton {
            visible: root.canOpen
            icon: "󰐕"
            onClicked: {
                if (root.windowCount === 0 && root.canActivateTray)
                    root.trayItem.activate();
                else if (root.desktopEntry)
                    root.desktopEntry.execute();
                else
                    root.dataSource.launchApp(root.appId);
                root.dismissRequested();
            }
        }

        HeaderIconButton {
            visible: root.canPin
            icon: "󰐃"
            active: root.pinned
            onClicked: {
                root.dataSource.togglePinned(root.appId);
                root.dismissRequested();
            }
        }
    }

    Rectangle {
        visible: root.hasBoth
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Theme.surfaceRadius
        color: Theme.panelSurface

        RowLayout {
            anchors { fill: parent; margins: 3 }
            spacing: 3

            TabChip { label: "Options"; selected: root.activeTab === "options"; onClicked: root.activeTab = "options" }
            TabChip { label: `Windows (${root.windowCount})`; selected: root.activeTab === "windows"; onClicked: root.activeTab = "windows" }
        }
    }

    Item {
        visible: root.showOptions || root.showWindows
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? Math.min(root.maxBodyHeight, bodyColumn.implicitHeight) : 0
        implicitHeight: Layout.preferredHeight

        Flickable {
            id: bodyScroll

            anchors { fill: parent; rightMargin: bodyScroll.interactive ? Theme.gap * 2 : 0 }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: bodyColumn

                width: bodyScroll.width
                spacing: Theme.gap / 2

                Repeater {
                    model: ScriptModel { values: root.showOptions ? root.desktopActions : [] }

                    Frame.PanelActionRow {
                        id: desktopActionRow
                        required property var modelData
                        Layout.fillWidth: true
                        rowHeight: 28
                        label: desktopActionRow.modelData.title
                        icon: desktopActionRow.modelData.icon || "󰘔"
                        iconSource: desktopActionRow.modelData.iconSource
                        monochromeIcon: true
                        onClicked: {
                            desktopActionRow.modelData.action.execute();
                            root.dismissRequested();
                        }
                    }
                }

                Frame.PanelMenuView {
                    id: menuView
                    visible: root.showOptions && root.appMenu !== null
                    Layout.fillWidth: true
                    menu: root.appMenu
                    onActivated: root.dismissRequested()
                }

                Repeater {
                    model: ScriptModel { values: root.showOptions ? root.gtkActions : [] }

                    Frame.PanelActionRow {
                        id: gtkActionRow
                        required property var modelData
                        Layout.fillWidth: true
                        rowHeight: 28
                        label: gtkActionRow.modelData.title
                        icon: gtkActionRow.modelData.icon || "󰘔"
                        onClicked: {
                            root.dataSource.activateGtkAction(gtkActionRow.modelData);
                            root.dismissRequested();
                        }
                    }
                }

                Repeater {
                    model: ScriptModel { values: root.showWindows ? (root.appGroup?.toplevels ?? []) : [] }

                    DockWindowRow {
                        id: windowRow
                        required property var modelData
                        Layout.fillWidth: true
                        dataSource: root.dataSource
                        toplevel: windowRow.modelData
                        previewsActive: root.previewsActive && root.showWindows
                        onActivated: root.dismissRequested()
                    }
                }
            }
        }

        Frame.PanelScrollIndicator {
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: 1 }
            flickable: bodyScroll
        }
    }
}
