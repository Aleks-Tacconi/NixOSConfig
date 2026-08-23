import QtQuick
import "../../theme"

/**
 * Compact labeled action used in the Wi-Fi toolbar.
 */
Rectangle {
    id: root

    required property string label
    required property string icon
    property bool active: false

    signal clicked

    implicitWidth: toolbarContent.implicitWidth + Theme.gap * 4
    implicitHeight: 32
    radius: Theme.surfaceRadius
    color: root.active ? Theme.panelSurfaceHover : (toolbarMouse.containsMouse && root.enabled ? Theme.panelSurface : "transparent")
    opacity: root.enabled ? 1 : 0.4

    Row {
        id: toolbarContent

        anchors.centerIn: parent
        spacing: Theme.gap

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
        id: toolbarMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
