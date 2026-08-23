import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"

/**
 * Rounded window thumbnail with overlaid title and controls.
 */
ClippingRectangle {
    id: root

    required property var dataSource
    required property var toplevel

    property bool previewsActive: false

    readonly property string title: root.toplevel?.title || root.toplevel?.appId || "Window"
    readonly property bool active: root.toplevel === root.dataSource.activeToplevel
    readonly property real previewHeight: Math.round(root.width * 9 / 16)

    signal activated

    implicitHeight: root.previewHeight
    height: implicitHeight
    radius: Theme.cardRadius
    color: Theme.panelSurface

    Loader {
        anchors.fill: parent
        active: root.previewsActive && width > 1 && height > 1 && root.toplevel !== null

        sourceComponent: ScreencopyView {
            captureSource: root.toplevel
            constraintSize: Qt.size(Math.max(1, Math.round(width)), Math.max(1, Math.round(height)))
            live: previewHover.hovered
        }
    }

    Rectangle {
        anchors.fill: parent
        color: previewHover.hovered ? "#10000000" : "transparent"
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 64
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#00000000"
            }
            GradientStop {
                position: 0.55
                color: "#80000000"
            }
            GradientStop {
                position: 1
                color: "#F0000000"
            }
        }
    }

    Text {
        id: windowTitle

        anchors {
            left: parent.left
            right: activeLabel.visible ? activeLabel.left : parent.right
            bottom: parent.bottom
            leftMargin: Theme.gap * 3
            rightMargin: Theme.gap * 2
            bottomMargin: Theme.gap * 2
        }
        text: root.title
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        font.bold: root.active
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }

    Text {
        id: activeLabel

        visible: root.active
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: Theme.gap * 3
            bottomMargin: Theme.gap * 2
        }
        text: "Active"
        color: Theme.fg
        opacity: 0.72
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelCaptionSize
    }

    HoverHandler {
        id: previewHover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.handleClick(mouse.button)
    }

    Rectangle {
        id: closeButton

        z: 2
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: Theme.gap * 2
            topMargin: Theme.gap * 2
        }
        width: 30
        height: 30
        radius: Theme.surfaceRadius
        color: closeMouse.containsMouse ? "#B0000000" : "#70000000"

        Text {
            anchors.centerIn: parent
            text: "×"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
        }

        MouseArea {
            id: closeMouse

            anchors.centerIn: parent
            width: 38
            height: 38
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeWindow()
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
