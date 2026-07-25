pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "window-layout.js" as WindowLayout

/**
 * Draggable preview for a single window.
 */
Item {
    id: root

    required property var dataSource
    required property var toplevel
    required property real homeX
    required property real homeY
    required property real maxWidth
    required property real maxHeight
    required property int hoveredWorkspace

    readonly property var hyprlandClient: dataSource.clientForToplevel(root.toplevel)
    readonly property size previewSize: WindowLayout.scaleWindow(root.hyprlandClient, root.maxWidth, root.maxHeight)
    readonly property int titleBarHeight: 30

    signal dragStateChanged(bool active)
    signal moveRequested(int workspaceId)
    signal activateRequested()
    signal closeRequested()

    width: Math.round(root.previewSize.width)
    height: Math.round(root.previewSize.height) + root.titleBarHeight
    z: dragHandler.active ? 10 : 1
    scale: dragHandler.active ? (root.hoveredWorkspace > 0 ? 0.8 : 0.95) : 1

    Component.onCompleted: root.resetPosition()

    onHomeXChanged: {
        if (!dragHandler.active)
            root.resetPosition()
    }

    onHomeYChanged: {
        if (!dragHandler.active)
            root.resetPosition()
    }

    function resetPosition() {
        root.x = root.homeX
        root.y = root.homeY
    }

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Drag.active: dragHandler.active
    Drag.source: root
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    Rectangle {
        anchors.fill: parent
        color: Theme.panelSurface
        border.width: 0
        radius: Theme.radius
        clip: true

        Rectangle {
            id: titleBar

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            height: root.titleBarHeight
            color: Theme.bg

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: Theme.gap
                    rightMargin: Theme.gap
                }

                color: Theme.fg
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                text: root.hyprlandClient?.title ?? root.hyprlandClient?.class ?? "window"
            }
        }

        ScreencopyView {
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            constraintSize: Qt.size(Math.round(root.previewSize.width), Math.round(root.previewSize.height))
            captureSource: root.toplevel
            live: true
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onTapped: eventPoint => {
            if (eventPoint.button === Qt.LeftButton)
                root.activateRequested()
            else if (eventPoint.button === Qt.MiddleButton)
                root.closeRequested()
        }
    }

    DragHandler {
        id: dragHandler

        target: root
        cursorShape: Qt.OpenHandCursor

        onActiveChanged: {
            root.dragStateChanged(active)

            if (!active) {
                if (root.hoveredWorkspace > 0 && root.hoveredWorkspace !== root.hyprlandClient?.workspace?.id)
                    root.moveRequested(root.hoveredWorkspace)

                root.resetPosition()
            }
        }
    }
}
