import QtQuick
import "../../theme"

/**
 * Compact notification action with primary and secondary emphasis.
 */
Rectangle {
    id: root

    required property var action
    property bool primary: false

    signal invoked(var action)

    readonly property bool hovered: actionMouse.containsMouse

    implicitWidth: Math.max(72, actionLabel.implicitWidth + Theme.gap * 6)
    implicitHeight: 34
    radius: Theme.surfaceRadius
    color: root.primary ? Theme.panelSurfaceHover : (root.hovered ? Theme.panelSurfaceHover : Theme.panelSurface)
    border.width: root.primary ? 1 : 0
    border.color: Theme.popupInnerEdge

    Text {
        id: actionLabel

        anchors {
            fill: parent
            margins: Theme.gap * 3
        }
        text: root.action?.text || "Open"
        color: root.primary || root.hovered ? Theme.fg : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        font.bold: root.primary
        elide: Text.ElideRight
        maximumLineCount: 1
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: actionMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.invoked(root.action)
    }
}
