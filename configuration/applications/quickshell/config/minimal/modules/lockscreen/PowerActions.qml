pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../theme"
import "../frame" as Frame

/** Reboot and power-off action buttons for the lockscreen and greeter. */
RowLayout {
    id: root

    property bool interactive: true

    spacing: Theme.panelItemGap

    Process {
        id: powerProcess
    }

    Repeater {
        model: [
            { label: "Reboot", icon: "󰜉", command: ["systemctl", "reboot"] },
            { label: "Power Off", icon: "⏻", command: ["systemctl", "poweroff"] }
        ]

        Frame.PanelSurface {
            id: actionBtn

            required property var modelData

            implicitWidth: btnContent.implicitWidth + Theme.panelPadding * 1.5
            implicitHeight: Theme.panelRowHeight
            radius: Theme.surfaceRadius

            Rectangle {
                anchors.fill: parent
                radius: actionBtn.radius
                color: Theme.launcherSelection
                opacity: btnMouse.containsMouse && root.interactive ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 120 }
                }
            }

            RowLayout {
                id: btnContent

                anchors.centerIn: parent
                spacing: Theme.gap * 1.5

                Text {
                    color: Theme.fg
                    font.family: Theme.iconFontFamily
                    font.pixelSize: Theme.fontSize
                    text: actionBtn.modelData.icon
                }

                Text {
                    color: btnMouse.containsMouse ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    text: actionBtn.modelData.label

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }
            }

            MouseArea {
                id: btnMouse

                anchors.fill: parent
                enabled: root.interactive
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    powerProcess.command = actionBtn.modelData.command;
                    powerProcess.running = true;
                }
            }
        }
    }
}
