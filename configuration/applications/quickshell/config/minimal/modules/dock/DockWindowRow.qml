pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"

/**
 * Live preview card for one window in the dock pullout.
 */
Rectangle {
    id: root

    required property var dataSource
    required property var toplevel

    property real titleHeight: 24
    property real previewHeight: 160
    property bool closing: false
    property var pendingClose: null

    readonly property string appId: root.toplevel?.appId ?? "window"
    readonly property string title: root.toplevel?.title ?? root.appId
    readonly property string iconSource: root.dataSource.iconSourceForApp(root.appId)
    readonly property bool hovered: hoverHandler.hovered

    signal closeRequested(var toplevel)

    height: root.titleHeight + root.previewHeight + Theme.gap * 2
    radius: Theme.surfaceRadius
    color: Theme.panelSurface
    border.width: 0
    clip: true

    Rectangle {
        id: titleBar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: root.titleHeight
        color: "transparent"

        IconImage {
            id: appIcon

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap * 2
            }

            visible: root.iconSource.length > 0
            width: 14
            height: 14
            source: root.iconSource
        }

        Text {
            anchors {
                left: appIcon.visible ? appIcon.right : parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap * 2
                rightMargin: root.titleHeight + Theme.gap * 2
            }

            color: Theme.fg
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            text: root.title
        }
    }

    Rectangle {
        anchors {
            top: titleBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Theme.gap
        }

        radius: Theme.surfaceRadius
        color: "transparent"
        clip: true

        Loader {
            anchors.fill: parent
            active: !root.closing && root.toplevel !== null

            sourceComponent: ScreencopyView {
                captureSource: root.toplevel
                constraintSize: Qt.size(Math.round(parent?.width ?? 1), Math.round(parent?.height ?? 1))
                live: true
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.toplevel?.activate()
            else if (mouse.button === Qt.MiddleButton)
                root.closeWindow()
        }
    }

    function closeWindow() {
        const window = root.toplevel

        if (root.closing)
            return

        root.closing = true
        root.pendingClose = window
        root.closeRequested(window)
        closeTimer.restart()
    }

    Timer {
        id: closeTimer

        interval: 200
        repeat: false
        onTriggered: {
            root.pendingClose?.close()
            root.pendingClose = null
        }
    }

    Rectangle {
        id: closeButton

        z: 4
        width: 16
        height: 16
        radius: Theme.radius
        color: closeMouse.containsMouse ? Theme.fg : Theme.panelSurfaceHover
        border.width: 0

        anchors {
            right: parent.right
            top: parent.top
            rightMargin: Theme.gap * 2
            topMargin: (root.titleHeight - height) / 2
        }

        Text {
            anchors.centerIn: parent
            color: closeMouse.containsMouse ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
            text: "x"
        }

        MouseArea {
            id: closeMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.closeWindow()
        }
    }

}
