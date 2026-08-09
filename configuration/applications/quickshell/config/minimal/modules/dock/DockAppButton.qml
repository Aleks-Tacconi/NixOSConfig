pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../../theme"

/**
 * Compact dock button for one application group.
 */
Item {
    id: root

    required property var appGroup
    required property var dataSource

    property int lastFocused: -1
    property alias activatorMouseArea: mouseArea

    readonly property int windowCount: root.appGroup?.toplevels?.length ?? 0
    readonly property int activeWindowIndex: root.appGroup?.toplevels?.findIndex(toplevel => toplevel === root.dataSource.activeToplevel) ?? -1
    readonly property int activeDotIndex: root.windowCount <= 3 ? root.activeWindowIndex : Math.min(root.activeWindowIndex, 2)
    readonly property bool activeApp: root.appGroup?.active ?? false
    readonly property bool pinned: root.appGroup?.pinned ?? false
    readonly property bool hovered: mouseArea.containsMouse
    readonly property string iconSource: root.dataSource.iconSourceForApp(root.appGroup?.appId ?? "")

    signal popupRequested(var appGroup, var activatorMouseArea)

    width: 30
    height: 30
    z: root.hovered ? 1 : 0

    onAppGroupChanged: root.lastFocused = -1

    function focusNextWindow() {
        if (root.windowCount <= 0) {
            root.dataSource.launchApp(root.appGroup.appId);
            return;
        }

        root.lastFocused = (root.lastFocused + 1) % root.windowCount;
        root.appGroup.toplevels[root.lastFocused].activate();
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: -Theme.gap
            rightMargin: -Theme.gap
        }
        radius: Theme.radius
        color: root.hovered ? Theme.panelSurfaceHover : "transparent"
    }

    Item {
        id: iconLayer

        width: 26
        height: 24
        anchors {
            centerIn: parent
            verticalCenterOffset: -2
        }

        IconImage {
            anchors.centerIn: parent
            visible: root.iconSource.length > 0
            width: 22
            height: 22
            source: root.iconSource
        }

        Text {
            anchors.centerIn: parent
            visible: root.iconSource.length === 0
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
            text: root.appGroup?.appId?.[0]?.toUpperCase() ?? "?"
        }
    }

    Row {
        anchors {
            bottom: parent.bottom
            bottomMargin: 0
            horizontalCenter: parent.horizontalCenter
        }

        visible: root.windowCount > 0
        spacing: 3

        Repeater {
            model: Math.min(root.windowCount, 3)

            delegate: Rectangle {
                required property int index

                width: root.windowCount > 3 ? 3 : 6
                height: 2
                radius: 1
                color: root.activeDotIndex === index ? Theme.red : Theme.muted
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors {
            left: parent.left
            leftMargin: -Theme.gap / 2
            right: parent.right
            rightMargin: -Theme.gap / 2
            top: parent.top
            bottom: parent.bottom
        }

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.popupRequested(root.appGroup, mouseArea);
            else
                root.focusNextWindow();
        }
    }
}
