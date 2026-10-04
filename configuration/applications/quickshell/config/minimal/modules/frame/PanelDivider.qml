import QtQuick
import "../../theme"

/**
 * Shared short separator between popup content sections.
 */
Item {
    id: root

    property bool fullWidth: false

    implicitWidth: 72
    implicitHeight: 1
    width: parent?.width ?? implicitWidth
    height: 1

    Rectangle {
        anchors.centerIn: parent
        width: root.fullWidth ? root.width : Math.min(72, root.width * 0.25)
        height: 1
        radius: 1
        color: Theme.panelDivider
    }
}
