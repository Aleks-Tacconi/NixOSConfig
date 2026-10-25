pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"

/** Dock-sized tray icon with native activation and menu actions. */
Item {
    id: root

    required property var trayItem
    property bool menuOpen: false
    property var desktopEntry: null
    readonly property string applicationIcon: root.desktopEntry?.icon
        ? (Quickshell.iconPath(root.desktopEntry.icon.replace(/-symbolic$/, ""), true)
            || Quickshell.iconPath(root.desktopEntry.icon, true)) : ""
    signal menuRequested(var item, var activator)

    width: Theme.panelRowHeight - Theme.gap / 2
    height: width
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.trayItem.title || root.trayItem.id
    Accessible.onPressAction: root.activate()
    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()
    Keys.onMenuPressed: root.menuRequested(root.trayItem, mouseArea)

    /** Activate the app, respecting tray entries that only provide a menu. */
    function activate() {
        if (root.trayItem.onlyMenu)
            root.menuRequested(root.trayItem, mouseArea);
        else
            root.trayItem.activate();
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -Theme.gap / 2
        anchors.rightMargin: -Theme.gap / 2
        radius: Theme.radius
        color: mouseArea.containsMouse || root.menuOpen || root.activeFocus ? Theme.panelSurfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    IconImage {
        anchors.centerIn: parent
        width: root.width - Theme.gap * 2
        height: width
        source: root.applicationIcon || root.trayItem.icon || Quickshell.iconPath("application-x-executable")
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.gap * 1.5
        height: Theme.gap / 2
        radius: Theme.gap / 4
        color: Theme.muted
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.trayItem.secondaryActivate();
            else if (mouse.button === Qt.RightButton)
                root.menuRequested(root.trayItem, mouseArea);
            else
                root.activate();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0)
                root.trayItem.scroll(wheel.angleDelta.y, false);
            else if (wheel.angleDelta.x !== 0)
                root.trayItem.scroll(wheel.angleDelta.x, true);
        }
    }
}
