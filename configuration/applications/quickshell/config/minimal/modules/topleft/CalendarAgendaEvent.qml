pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"

/** Quiet agenda row with time, title, and an action revealed on interaction. */
Rectangle {
    id: root

    required property var event
    required property date now
    readonly property bool ongoing: root.event.startTime.length > 0 && root.event.startAt !== null
        && root.event.endAt !== null && root.event.startAt <= root.now && root.now <= root.event.endAt
    readonly property bool past: root.event.endAt !== null && root.event.endAt < root.now
    readonly property bool hovered: mouse.containsMouse

    signal activated

    height: 40
    implicitHeight: 40
    radius: Theme.surfaceRadius
    color: root.hovered ? Theme.panelSurfaceHover : (root.ongoing ? Theme.panelSurfaceHover : Theme.panelSurface)
    opacity: root.past ? 0.6 : 1.0

    Behavior on color {
        ColorAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        visible: root.ongoing
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 4
        }
        width: 3
        radius: 1.5
        color: Theme.red
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: root.ongoing ? Theme.gap * 3.5 : Theme.gap * 2.5
            rightMargin: Theme.gap * 2.5
        }
        spacing: Theme.gap * 2

        Column {
            Layout.preferredWidth: 60
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                text: root.ongoing ? "Now" : (root.event.startTime || "All day")
                color: root.ongoing ? Theme.fg : (root.event.startTime.length > 0 ? Theme.red : Theme.muted)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                font.bold: root.ongoing || root.event.startTime.length > 0
            }

            Text {
                visible: root.event.endTime.length > 0
                text: root.event.endTime
                color: Theme.muted
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize - 1
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.event.title
            textFormat: Text.PlainText
            color: root.past ? Theme.muted : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            font.weight: root.ongoing ? Theme.emphasisWeight : Font.Normal
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            Layout.preferredWidth: Theme.fontSize
            Layout.alignment: Qt.AlignVCenter
            text: "↗"
            color: root.hovered ? Theme.fg : Theme.muted
            opacity: root.hovered ? 1.0 : 0.4
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            horizontalAlignment: Text.AlignRight

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
