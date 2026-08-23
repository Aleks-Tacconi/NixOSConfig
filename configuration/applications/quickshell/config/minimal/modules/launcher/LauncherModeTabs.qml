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
            icon: "󰕮"
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
    height: 40
    radius: Theme.surfaceRadius
    color: Theme.panelSurface
    border.width: 0

    signal modeRequested(string mode)

    Row {
        anchors {
            fill: parent
            margins: 3
        }

        spacing: 2

        Repeater {
            model: root.modes

            delegate: Item {
                id: tabRoot

                required property var modelData

                readonly property bool active: modelData.key === root.mode
                readonly property bool hovered: mouseArea.containsMouse

                width: (parent.width - parent.spacing * Math.max(0, root.modes.length - 1)) / root.modes.length
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.surfaceRadius
                    color: parent.active ? Theme.panelSurfaceHover : (parent.hovered ? Theme.glassHighlight : "transparent")
                    border.width: 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.gap * 2

                    Text {
                        color: tabRoot.active ? Theme.fg : Theme.muted
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
