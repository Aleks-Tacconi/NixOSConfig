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
    signal copyRequested
    signal hoveredRequested

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool copyable: ["file", "emoji", "clipboard"].includes(root.item.kind)
    readonly property string actionIcon: root.item.kind === "application" || root.item.kind === "file" ? "" : (root.item.kind === "directory" ? "" : "")

    radius: Theme.surfaceRadius
    color: root.selected ? Theme.panelSurfaceHover : (root.hovered ? Theme.panelSurface : "transparent")
    border.width: root.selected ? 1 : 0
    border.color: Theme.popupInnerEdge

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }

    Rectangle {
        visible: root.selected
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
        radius: 2
        color: Theme.fg
    }

    Row {
        z: 1

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
                textFormat: Text.PlainText
            }

            Text {
                width: parent.width
                visible: (root.item.subtitle ?? "").length > 0
                color: Theme.muted
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                text: root.item.subtitle
                textFormat: Text.PlainText
            }
        }

        Rectangle {
            id: actionPill

            width: root.copyable ? 68 : Theme.fontSize + 14
            height: root.copyable ? 34 : parent.height
            anchors.verticalCenter: parent.verticalCenter
            radius: Theme.surfaceRadius
            color: copyMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"
            border.width: root.copyable && root.selected ? 1 : 0
            border.color: Theme.popupInnerEdge

            Text {
                id: actionLabel

                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: root.selected ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: root.copyable ? Theme.panelCaptionSize : Theme.panelBodySize
                font.bold: root.copyable
                text: root.copyable ? "  Copy" : root.actionIcon
            }

            MouseArea {
                id: copyMouse

                anchors.fill: parent
                enabled: root.copyable
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.copyRequested()
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
