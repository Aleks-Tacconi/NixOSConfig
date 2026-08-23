import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"

/**
 * Rounded window preview with compact title and close controls.
 */
ClippingRectangle {
    id: root

    required property var dataSource
    required property var toplevel

    property bool previewsActive: false
    property real footerHeight: 36

    readonly property string title: root.toplevel?.title || root.toplevel?.appId || "Window"
    readonly property bool active: root.toplevel === root.dataSource.activeToplevel
    readonly property real previewHeight: Math.round(root.width * 9 / 16)

    signal activated

    implicitHeight: root.previewHeight + root.footerHeight
    height: implicitHeight
    radius: Theme.cardRadius
    color: Theme.panelSurface

    Column {
        anchors.fill: parent
        spacing: 0

        Item {
            id: mediaFrame

            width: parent.width
            height: root.previewHeight

            Loader {
                anchors.fill: parent
                active: root.previewsActive && width > 1 && height > 1 && root.toplevel !== null

                sourceComponent: ScreencopyView {
                    captureSource: root.toplevel
                    constraintSize: Qt.size(Math.max(1, Math.round(width)), Math.max(1, Math.round(height)))
                    live: mediaHover.hovered
                }
            }

            Rectangle {
                anchors.fill: parent
                color: mediaHover.hovered ? "#12000000" : "transparent"
            }

            HoverHandler {
                id: mediaHover
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => root.handleClick(mouse.button)
            }
        }

        Rectangle {
            width: parent.width
            height: root.footerHeight
            color: root.active || footerHover.hovered ? Theme.panelSurfaceHover : "transparent"

            Rectangle {
                visible: root.active
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 3
                height: 18
                radius: 2
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

            HoverHandler {
                id: footerHover
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
