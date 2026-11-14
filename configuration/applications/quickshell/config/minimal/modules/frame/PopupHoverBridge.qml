pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Track the popup button and its gap in the popup's own input surface. */
Item {
    id: root

    property Item activator: null
    readonly property bool hovered: bridgeMouse.containsMouse
    signal activated

    width: root.activator?.width ?? 0
    height: Theme.barHeight + Theme.popupGap

    MouseArea {
        id: bridgeMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
