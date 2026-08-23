import QtQuick
import Quickshell.Wayland
import "../../theme"

/**
 * Live window preview with compact title and close controls.
 */
Rectangle {
    id: root

    required property var dataSource
    required property var toplevel

    property real footerHeight: 36

    readonly property string title: root.toplevel?.title || root.toplevel?.appId || "Window"
    readonly property bool active: root.toplevel === root.dataSource.activeToplevel
    readonly property real previewHeight: Math.round(root.width / 2)

    signal activated

    implicitHeight: root.previewHeight + root.footerHeight
    radius: Theme.cardRadius
    color: Theme.panelSurface
    border.width: root.active ? 1 : 0
    border.color: Theme.popupBorder
    clip: true

    Loader {
        id: previewLoader

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: root.previewHeight
        active: root.visible && root.toplevel !== null

        sourceComponent: ScreencopyView {
            captureSource: root.toplevel
            constraintSize: Qt.size(Math.max(1, Math.round(parent?.width ?? 1)), Math.max(1, Math.round(parent?.height ?? 1)))
            live: true
        }

        Rectangle {
            z: 1
            anchors.fill: parent
            color: previewMouse.containsMouse ? "#12000000" : "transparent"
        }

        MouseArea {
            id: previewMouse

            z: 2
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => root.handleClick(mouse.button)
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: root.footerHeight
        color: root.active ? Theme.panelSurfaceHover : Theme.panelSurface

        Rectangle {
            visible: root.active
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 3
            color: Theme.fg
        }

        Text {
            anchors {
                left: parent.left
                right: closeButton.left
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.gap * 3
                rightMargin: Theme.gap * 2
            }
            text: root.title
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            font.bold: root.active
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        MouseArea {
            anchors {
                left: parent.left
                right: closeButton.left
                top: parent.top
                bottom: parent.bottom
            }
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => root.handleClick(mouse.button)
        }

        Rectangle {
            id: closeButton

            anchors {
                right: parent.right
                rightMargin: Theme.gap
                verticalCenter: parent.verticalCenter
            }
            width: 30
            height: 30
            radius: Theme.surfaceRadius
            color: closeMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: "×"
                color: closeMouse.containsMouse ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeWindow()
            }
        }
    }

    function handleClick(button) {
        if (button === Qt.MiddleButton) {
            root.closeWindow();
            return;
        }
        root.toplevel?.activate();
        root.activated();
    }

    function closeWindow() {
        root.toplevel?.close();
    }
}
