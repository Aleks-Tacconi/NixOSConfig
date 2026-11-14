pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../frame" as Frame
import "app-menu-actions.js" as Actions

/**
 * Popup content showing application actions, native D-Bus menu, and window details.
 */
FocusScope {
    id: root

    property real maxPopupDepth: 520
    readonly property real desiredDepth: Math.min(root.maxPopupDepth,
        actionsContent.implicitHeight
            + (detailsSection.visible ? detailsContent.implicitHeight + Theme.panelItemGap : 0)
            + Theme.panelPadding * 2)

    signal dismissRequested

    function resetMenu() {
        nativeMenuView.reset();
    }

    Flickable {
        id: actionsScroll

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: detailsSection.top
            topMargin: Theme.panelPadding
            leftMargin: Theme.panelPadding
            rightMargin: Theme.panelPadding
            bottomMargin: detailsSection.visible ? Theme.panelItemGap : 0
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: actionsScroll.width
        contentHeight: actionsContent.implicitHeight
        interactive: actionsScroll.contentHeight > actionsScroll.height

        ColumnLayout {
            id: actionsContent

            width: actionsScroll.width
            spacing: Theme.panelItemGap

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot && (AppMenuService.canLaunchNewWindow || AppMenuService.specificActionItems.length > 0)
                title: "Actions"
            }

            Frame.PanelActionRow {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot && AppMenuService.canLaunchNewWindow
                icon: ""
                label: "New Window"
                onClicked: {
                    AppMenuService.launchNewWindow();
                    root.dismissRequested();
                }
            }

            Repeater {
                model: ScriptModel {
                    values: AppMenuService.specificActionItems
                }

                Frame.PanelActionRow {
                    id: actionRow

                    required property var modelData

                    Layout.fillWidth: true
                    visible: nativeMenuView.atRoot
                    icon: Actions.actionGlyph(actionRow.modelData.title)
                    iconSource: AppMenuService.actionIconSource(actionRow.modelData.desktopAction?.icon, true)
                    label: actionRow.modelData.title
                    showTrailing: false
                    onClicked: {
                        if (actionRow.modelData.kind === "desktop")
                            actionRow.modelData.desktopAction.execute();
                        else
                            AppMenuService.activateGtkAction(actionRow.modelData.gtkAction);
                        root.dismissRequested();
                    }
                }
            }

            Frame.PanelDivider {
                Layout.fillWidth: true
                fullWidth: true
                visible: nativeMenuView.atRoot && AppMenuService.hasNativeMenu
            }

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot && AppMenuService.hasNativeMenu
                title: "Menu"
            }

            Frame.PanelMenuView {
                id: nativeMenuView

                visible: AppMenuService.hasNativeMenu
                Layout.fillWidth: true
                menu: AppMenuService.nativeMenu
                onActivated: root.dismissRequested()
            }

            Frame.PanelDivider {
                Layout.fillWidth: true
                fullWidth: true
                visible: nativeMenuView.atRoot
            }

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot
                title: "Application"
            }

            Frame.PanelActionRow {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot
                icon: "󰅖"
                label: "Close Window"
                onClicked: {
                    AppMenuService.closeActiveWindow();
                    root.dismissRequested();
                }
            }

            Frame.PanelActionRow {
                Layout.fillWidth: true
                visible: nativeMenuView.atRoot
                icon: "󰅚"
                label: "Force Quit"
                accentColor: Theme.red
                onClicked: {
                    AppMenuService.forceQuitActiveWindow();
                    root.dismissRequested();
                }
            }
        }
    }

    Item {
        id: detailsSection

        visible: nativeMenuView.atRoot
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.panelPadding
            rightMargin: Theme.panelPadding
            bottomMargin: Theme.panelPadding
        }
        height: detailsSection.visible ? detailsContent.implicitHeight : 0

        ColumnLayout {
            id: detailsContent

            width: parent.width
            spacing: Theme.gap

            Frame.PanelDivider {
                Layout.fillWidth: true
                fullWidth: true
            }

            Item {
                Layout.preferredHeight: Theme.gap
            }

            WindowDetails {
                Layout.fillWidth: true
                windowTitle: AppMenuService.windowTitle
                pid: AppMenuService.activePid > 0 ? String(AppMenuService.activePid) : "Unknown"
                className: AppMenuService.className
                workspace: AppMenuService.workspace
            }
        }
    }

    Frame.PanelScrollIndicator {
        anchors {
            top: actionsScroll.top
            right: parent.right
            bottom: actionsScroll.bottom
            rightMargin: Theme.gap
        }
        flickable: actionsScroll
    }
}
