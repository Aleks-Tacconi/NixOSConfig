pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/**
 * Full-width mode selector for the launcher.
 */
Rectangle {
    id: root

    required property string mode
    required property var enabledModes
    readonly property var modes: [
        {
            key: "applications",
            label: "Apps",
            icon: ""
        },
        {
            key: "files",
            label: "Files",
            icon: "󰈔"
        },
        {
            key: "emoji",
            label: "Emoji",
            icon: "󰞅"
        },
        {
            key: "clipboard",
            label: "Copy",
            icon: ""
        }
    ].filter(item => root.enabledModes.includes(item.key))
    height: 42
    radius: Theme.surfaceRadius
    color: "transparent"
    border.width: 0

    signal modeRequested(string mode)

    Row {
        anchors {
            fill: parent
            margins: 0
        }

        spacing: Theme.gap

        Repeater {
            model: root.modes

            delegate: Item {
                id: tabRoot

                required property var modelData

                readonly property bool active: modelData.key === root.mode
                readonly property bool hovered: mouseArea.containsMouse

                width: (parent.width - Theme.gap * Math.max(0, root.modes.length - 1)) / root.modes.length
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.surfaceRadius
                    color: parent.active ? Theme.panelSurfaceHover : (parent.hovered ? Theme.panelSurface : "transparent")
                    border.width: parent.active ? 1 : 0
                    border.color: Theme.popupInnerEdge

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Rectangle {
                    visible: tabRoot.active
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: Theme.gap * 3
                        rightMargin: Theme.gap * 3
                    }
                    height: 2
                    radius: 1
                    color: Theme.fg
                    opacity: 0.82
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.gap * 2

                    Text {
                        color: tabRoot.active ? Theme.red : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelBodySize
                        text: tabRoot.modelData.icon
                    }

                    Text {
                        color: tabRoot.active ? Theme.fg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        font.bold: tabRoot.active
                        text: tabRoot.modelData.label
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.modeRequested(tabRoot.modelData.key)
                }
            }
        }
    }
}
