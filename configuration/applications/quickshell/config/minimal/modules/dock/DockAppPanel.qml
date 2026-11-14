pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../frame" as Frame
import "../../theme"

/**
 * Unified dock panel presenting application actions, exposed menus, and window previews.
 */
ColumnLayout {
    id: root

    required property var appGroup
    required property var dataSource
    property bool previewsActive: false
    property real maxBodyHeight: 420

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
    readonly property bool hasOptions: root.appMenu !== null || root.gtkActions.length > 0
    readonly property bool hasPrimaryActions: root.canOpen || root.canPin || root.desktopActions.length > 0

    signal dismissRequested

    spacing: Theme.panelItemGap
    onAppGroupChanged: {
        if (root.appMenu === null)
            root.dataSource.ensureGtkActionsForGroup(root.appGroup);
    }

    function resetMenu() {
        menuView.reset();
    }

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
                font.weight: Theme.emphasisWeight
            }
        }

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: root.appName
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.maxBodyHeight, bodyColumn.implicitHeight)
        implicitHeight: Layout.preferredHeight

        Flickable {
            id: bodyScroll

            anchors {
                fill: parent
                rightMargin: Theme.gap * 2
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: bodyColumn.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
                id: bodyColumn

                width: bodyScroll.width
                spacing: Theme.panelItemGap

                Frame.PanelActionRow {
                    visible: root.canOpen
                    Layout.fillWidth: true
                    label: root.windowCount > 0 ? "New window" : "Open"
                    icon: "󰐕"
                    showTrailing: false
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

                Repeater {
                    model: ScriptModel {
                        values: root.desktopActions
                    }

                    Frame.PanelActionRow {
                        id: desktopActionRow

                        required property var modelData

                        Layout.fillWidth: true
                        label: desktopActionRow.modelData.title
                        icon: "󰘔"
                        iconSource: desktopActionRow.modelData.iconSource
                        showTrailing: false
                        onClicked: {
                            desktopActionRow.modelData.action.execute();
                            root.dismissRequested();
                        }
                    }
                }

                Frame.PanelActionRow {
                    visible: root.canPin
                    Layout.fillWidth: true
                    label: root.pinned ? "Unpin from dock" : "Pin to dock"
                    icon: "󰐃"
                    showTrailing: false
                    onClicked: {
                        root.dataSource.togglePinned(root.appId);
                        root.dismissRequested();
                    }
                }

                Frame.PanelDivider {
                    visible: root.hasPrimaryActions && root.hasOptions
                    Layout.fillWidth: true
                    fullWidth: true
                }

                Frame.PanelGroupLabel {
                    visible: (root.hasPrimaryActions || root.windowCount > 0) && root.hasOptions
                    Layout.fillWidth: true
                    title: "Options"
                }

                Frame.PanelMenuView {
                    id: menuView

                    visible: root.appMenu !== null
                    Layout.fillWidth: true
                    menu: root.appMenu
                    onActivated: root.dismissRequested()
                }

                Repeater {
                    model: ScriptModel {
                        values: root.gtkActions
                    }

                    Frame.PanelActionRow {
                        id: gtkActionRow

                        required property var modelData

                        Layout.fillWidth: true
                        label: gtkActionRow.modelData.title
                        icon: "󰘔"
                        showTrailing: false
                        onClicked: {
                            root.dataSource.activateGtkAction(gtkActionRow.modelData);
                            root.dismissRequested();
                        }
                    }
                }

                Frame.PanelDivider {
                    visible: (root.hasPrimaryActions || root.hasOptions) && root.windowCount > 0
                    Layout.fillWidth: true
                    fullWidth: true
                }

                Frame.PanelGroupLabel {
                    visible: root.windowCount > 0
                    Layout.fillWidth: true
                    title: "Windows"
                    detail: String(root.windowCount)
                }

                Repeater {
                    model: ScriptModel {
                        values: root.appGroup?.toplevels ?? []
                    }

                    DockWindowRow {
                        id: windowRow

                        required property var modelData

                        Layout.fillWidth: true
                        dataSource: root.dataSource
                        toplevel: windowRow.modelData
                        previewsActive: root.previewsActive
                        onActivated: root.dismissRequested()
                    }
                }
            }
        }

        Frame.PanelScrollIndicator {
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                rightMargin: 1
            }
            flickable: bodyScroll
        }
    }
}
