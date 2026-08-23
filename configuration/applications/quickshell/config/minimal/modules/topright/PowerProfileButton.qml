import QtQuick
import "../../theme"

/**
 * Selectable power-profile segment.
 */
Rectangle {
    id: root

    required property string label
    required property string icon
    property bool active: false

    signal clicked

    implicitHeight: 40
    radius: Theme.surfaceRadius
    color: root.active ? Theme.panelSurfaceHover : (profileMouse.containsMouse && root.enabled ? Theme.panelSurface : "transparent")
    opacity: root.enabled ? 1 : 0.38
    border.width: root.active ? 1 : 0
    border.color: Theme.popupInnerEdge

    Row {
        anchors.centerIn: parent
        spacing: Theme.gap * 2

        Text {
            text: root.icon
            color: root.active ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
        }

        Text {
            text: root.label
            color: root.active ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            font.bold: root.active
        }
    }

    MouseArea {
        id: profileMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
