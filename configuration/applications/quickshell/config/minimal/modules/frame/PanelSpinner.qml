import QtQuick
import "../../theme"

/**
 * Compact animated progress indicator for panel loading states.
 */
Item {
    id: root

    property bool running: true
    property real spinnerSize: 16

    implicitWidth: root.spinnerSize
    implicitHeight: root.spinnerSize

    Text {
        id: spinnerIcon

        anchors.centerIn: parent
        text: "󰑐"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: root.spinnerSize
    }

    RotationAnimation {
        target: spinnerIcon
        property: "rotation"
        from: 0
        to: 360
        duration: 850
        loops: Animation.Infinite
        running: root.running && root.visible
    }
}
