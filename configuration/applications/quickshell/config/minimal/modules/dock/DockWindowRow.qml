import QtQuick
import "../../theme"

/**
 * Compact activate/close row for one application window.
 */
Rectangle {
    id: root

    required property var dataSource
    required property var toplevel

    readonly property string title: root.toplevel?.title || root.toplevel?.appId || "Window"
    readonly property bool active: root.toplevel === root.dataSource.activeToplevel

    signal activated

    implicitHeight: 42
    radius: Theme.surfaceRadius
    color: root.active ? Theme.panelSurfaceHover : (rowMouse.containsMouse ? Theme.panelSurface : "transparent")
    border.width: root.active ? 1 : 0
    border.color: Theme.popupInnerEdge

    Rectangle {
        visible: root.active
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
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

    MouseArea {
        id: rowMouse

        anchors {
            left: parent.left
            right: closeButton.left
            top: parent.top
            bottom: parent.bottom
        }
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.closeWindow();
            else {
                root.toplevel?.activate();
                root.activated();
            }
        }
    }

    Rectangle {
        id: closeButton

        anchors {
            right: parent.right
            rightMargin: Theme.gap
            verticalCenter: parent.verticalCenter
        }
        width: 32
        height: 32
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

    function closeWindow() {
        const window = root.toplevel;
        if (!window)
            return;
        window.close();
    }
}
