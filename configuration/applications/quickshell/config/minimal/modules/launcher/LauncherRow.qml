pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../../theme"

/**
 * Selectable launcher result row.
 */
Rectangle {
    id: root

    required property var item
    property bool selected: false

    signal activated
    signal hoveredRequested

    readonly property bool hovered: mouseArea.containsMouse
    readonly property string actionIcon: root.item.kind === "application" || root.item.kind === "file" ? "" : (root.item.kind === "directory" ? "" : "")

    radius: Theme.surfaceRadius
    color: root.selected || root.hovered ? Theme.panelSurfaceHover : "transparent"
    border.width: 0

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }

    Row {
        anchors {
            fill: parent
            leftMargin: Theme.panelPadding - 4
            rightMargin: Theme.panelPadding - 4
        }

        spacing: Theme.panelItemGap + Theme.gap

        Rectangle {
            width: 42
            height: 42
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.surfaceRadius
            color: "transparent"
            border.width: 0

            IconImage {
                anchors.centerIn: parent
                visible: (root.item.icon ?? "").length > 0
                width: 26
                height: 26
                source: root.item.icon ?? ""
            }

            Text {
                anchors.centerIn: parent
                visible: (root.item.icon ?? "").length === 0
                color: root.selected ? Theme.red : Theme.fg
                font.family: root.item.kind === "emoji" ? "sans-serif" : Theme.fontFamily
                font.pixelSize: root.item.kind === "emoji" ? 23 : Theme.panelBodySize
                font.bold: root.item.kind !== "emoji"
                text: root.item.kind === "emoji" ? (root.item.glyph ?? root.item.title) : (root.item.kind === "file" ? "󰈔" : (root.item.kind === "directory" ? "" : (root.item.title?.[0]?.toUpperCase() ?? "?")))
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 42 - actionPill.width - parent.spacing * 2
            spacing: 2

            Text {
                width: parent.width
                color: Theme.fg
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                font.bold: true
                text: root.item.title
            }

            Text {
                width: parent.width
                visible: (root.item.subtitle ?? "").length > 0
                color: Theme.muted
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                text: root.item.subtitle
            }
        }

        Rectangle {
            id: actionPill

            width: Theme.fontSize + 14
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.width: 0

            Text {
                id: actionLabel

                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: root.selected ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                text: root.actionIcon
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
        onEntered: root.hoveredRequested()
    }
}
