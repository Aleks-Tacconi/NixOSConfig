pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/**
 * Consistent media control with a full pointer target.
 */
Rectangle {
    id: root

    required property string icon
    property bool primary: false
    property real controlSize: 40

    signal clicked

    implicitWidth: root.controlSize
    implicitHeight: root.controlSize
    radius: Theme.surfaceRadius
    color: root.primary ? Theme.panelSurfaceHover : (controlMouse.containsMouse && root.enabled ? Theme.panelSurface : "transparent")
    opacity: root.enabled ? 1 : 0.38
    border.width: root.primary ? 1 : 0
    border.color: Theme.popupInnerEdge

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.primary ? Theme.fg : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 2
    }

    MouseArea {
        id: controlMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
