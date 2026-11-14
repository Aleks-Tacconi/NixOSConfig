pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/**
 * Top-bar interactive button with a hover and active pill background.
 */
Item {
    id: root

    default property alias content: contentHost.data
    readonly property alias mouseArea: pillMouseArea
    readonly property bool hovered: pillMouseArea.containsMouse
    property bool active: false
    property real pillHeight: Theme.panelRowHeight
    property real pillLeftMargin: 0
    property real pillRightMargin: 0

    signal clicked
    signal wheel(var wheel)

    height: Theme.barHeight
    z: root.hovered ? 1 : 0

    Rectangle {
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: root.pillLeftMargin
            rightMargin: root.pillRightMargin
        }
        height: root.pillHeight
        radius: Theme.radius
        color: root.hovered || root.active ? Theme.panelSurfaceHover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Item {
        id: contentHost

        anchors.fill: parent
    }

    MouseArea {
        id: pillMouseArea

        anchors {
            top: parent.top
            bottom: parent.bottom
            bottomMargin: -Theme.popupGap
            left: parent.left
            right: parent.right
            leftMargin: root.pillLeftMargin
            rightMargin: root.pillRightMargin
        }
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onWheel: wheel => root.wheel(wheel)
    }
}
