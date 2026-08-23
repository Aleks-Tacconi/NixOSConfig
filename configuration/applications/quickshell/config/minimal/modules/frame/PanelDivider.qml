import QtQuick
import "../../theme"

/**
 * Shared short separator between popup content sections.
 */
Item {
    id: root

    implicitWidth: 72
    implicitHeight: 1
    width: parent?.width ?? implicitWidth
    height: 1

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(72, root.width * 0.25)
        height: 1
        radius: 1
        color: Theme.panelDivider
    }
}
