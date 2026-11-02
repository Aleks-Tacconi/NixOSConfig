pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../dock" as Dock
import "../frame" as Frame
import "../../theme"

/** Inline tray icons for the dock, with a shared application menu popup. */
Row {
    id: root

    property var popupScreen: null
    property real popupRightMargin: Theme.gap * 2
    property real buttonSize: Theme.panelRowHeight - Theme.gap / 2
    property var entries: []
    property var activeItem: null
    property var activator: null
    readonly property var trayItems: SystemTray.items.values
    readonly property bool menuOpen: root.activeItem !== null && root.activeItem.hasMenu
    readonly property var activeEntry: root.entries.find(entry => entry.item === root.activeItem) ?? null
    readonly property string menuTitle: root.activeEntry?.desktopEntry?.name || root.activeItem?.title || root.activeItem?.id || ""
    signal menuRequested

    spacing: Theme.gap
    visible: root.entries.length > 0
    height: root.buttonSize

    onTrayItemsChanged: {
        if (root.activeItem && !root.trayItems.includes(root.activeItem))
            root.closeMenu();
    }

    /** Clear the current tray menu and its hover anchor. */
    function closeMenu() {
        root.activeItem = null;
        root.activator = null;
    }

    /** Toggle an item's menu and close any dock window picker. */
    function openMenu(item, mouseArea) {
        if (!item.hasMenu)
            return;
        if (root.activeItem === item) {
            root.closeMenu();
            return;
        }
        root.menuRequested();
        root.activeItem = item;
        root.activator = mouseArea;
    }

    Repeater {
        model: root.entries

        Dock.DockTrayButton {
            required property var modelData
            width: root.buttonSize
            height: root.buttonSize
            trayItem: modelData.item
            desktopEntry: modelData.desktopEntry
            menuOpen: root.activeItem === modelData.item
            onMenuRequested: (item, activator) => root.openMenu(item, activator)
        }
    }

    PanelWindow {
        id: trayWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.menuOpen || trayPanel.progress > 0
        implicitWidth: Theme.panelRowHeight * 10
        implicitHeight: trayPanel.depth
        mask: Region { item: trayPanel }
        WlrLayershell.namespace: "quickshell:systemTray"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; right: true }
        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.popupRightMargin
        }

        Frame.PulloutPanel {
            id: trayPanel

            anchors { top: parent.top; right: parent.right }
            requestedOpen: root.menuOpen
            activatorMouseArea: root.activator
            clickDismiss: true
            closeDelay: Theme.popupDismissDelay
            hoverLeaseDuration: 1200
            duration: 180
            length: trayWindow.width
            depth: Math.min(menuHeader.implicitHeight + Theme.panelItemGap + menuView.implicitHeight + Theme.panelPadding * 2,
                Math.max(0, (root.popupScreen?.height ?? Theme.panelRowHeight * 20) - Theme.barHeight - Theme.popupGap - Theme.panelPadding))
            backgroundColor: Theme.panelBg
            corner: "topRight"
            curveRadius: Theme.panelRadius
            onDismissRequested: root.closeMenu()

            Frame.PanelSectionHeader {
                id: menuHeader

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: Theme.panelPadding
                }
                title: root.menuTitle
            }

            Flickable {
                id: menuScroll

                anchors {
                    top: menuHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: Theme.panelItemGap
                    leftMargin: Theme.panelPadding
                    rightMargin: Theme.panelPadding
                    bottomMargin: Theme.panelPadding
                }
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: menuView.implicitHeight
                interactive: contentHeight > height

                Frame.PanelMenuView {
                    id: menuView

                    width: menuScroll.width
                    menu: root.activeItem?.menu ?? null
                    onActivated: root.closeMenu()
                }
            }

            Frame.PanelScrollIndicator {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    margins: Theme.panelPadding
                }
                flickable: menuScroll
            }
        }
    }
}
