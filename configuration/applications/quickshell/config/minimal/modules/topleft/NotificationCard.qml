import QtQuick
import "../../theme"

Rectangle {
    id: root

    required property var notification
    property bool toast: false
    property real cardPadding: root.toast ? Theme.gap * 3 : Theme.gap * 2

    signal dismissRequested(var notification)

    width: parent?.width ?? 0
    implicitHeight: Math.max(72, cardContent.implicitHeight + root.cardPadding * 2)
    height: implicitHeight
    radius: root.toast ? 0 : Theme.surfaceRadius
    color: root.toast ? "transparent" : Theme.panelSurface
    clip: true
    border.width: 0

    Rectangle {
        visible: !root.toast

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        width: 3
        color: Theme.red
        opacity: 0.8
    }

    Column {
        id: cardContent

        anchors {
            left: parent.left
            right: closeButton.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: root.toast ? root.cardPadding : root.cardPadding + 3
            rightMargin: Theme.gap
            topMargin: root.cardPadding
            bottomMargin: root.cardPadding
        }

        spacing: Theme.gap * 0.6

        Text {
            width: parent.width
            text: root.notification?.appName || "App"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.notification?.summary || "Notification"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
            font.bold: true
            maximumLineCount: 1
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            visible: (root.notification?.body || "").length > 0
            text: root.notification?.body || ""
            color: Theme.fg
            opacity: 0.82
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }

    Rectangle {
        id: closeButton

        width: 24
        height: 24
        radius: Theme.radius
        color: closeMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

        anchors {
            right: parent.right
            top: parent.top
            rightMargin: Theme.gap * 1.5
            topMargin: Theme.gap * 1.5
        }

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
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                root.dismissRequested(root.notification);
                root.notification?.dismiss();
            }
        }
    }
}
