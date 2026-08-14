import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../dock" as Dock
import "../power" as Power
import "../topleft/" as TopLeft
import "../topright/" as TopRight

Scope {
    id: root

    property var notificationCenter: null

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                left: 0
                right: 0
                top: 0
            }

            implicitHeight: Theme.barHeight
            implicitWidth: modelData.width
            color: "transparent"

            WlrLayershell.namespace: "quickshell:topBar"
            WlrLayershell.layer: WlrLayer.Top

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                radius: 0

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical

                        GradientStop {
                            position: 0
                            color: Theme.glassHighlightSoft
                        }

                        GradientStop {
                            position: 0.55
                            color: "transparent"
                        }

                        GradientStop {
                            position: 1
                            color: Theme.glassShadow
                        }
                    }
                }

                Row {
                    id: leftCluster

                    anchors {
                        left: parent.left
                        leftMargin: Theme.gap * 4
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.gap * 5 + 2

                    TopLeft.Init {
                        popupScreen: bar.modelData
                        notificationCenter: root.notificationCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    AppMenu {
                        id: appMenu

                        popupScreen: bar.modelData
                        parentWindow: bar
                        popupLeftMargin: leftCluster.x + appMenu.x - Theme.gap * 2
                        maxWidth: Math.max(132, Math.min(340, bar.width * 0.27))
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Workspaces {
                    id: workspaces

                    anchors.centerIn: parent
                }

                Row {
                    id: rightCluster

                    readonly property real outerMargin: Theme.gap * 4

                    anchors {
                        right: parent.right
                        rightMargin: rightCluster.outerMargin
                        verticalCenter: parent.verticalCenter
                    }

                    spacing: Theme.gap * 5 + 2

                    Dock.Init {
                        popupScreen: bar.modelData
                        maxWidth: Math.max(96, Math.min(300, bar.width * 0.24))
                        popupRightMargin: rightCluster.outerMargin + statusPowerCluster.width + tray.width + rightCluster.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Tray {
                        id: tray

                        popupScreen: bar.modelData
                        popupRightMargin: rightCluster.outerMargin + statusPowerCluster.width + rightCluster.spacing
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        id: statusPowerCluster

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.gap * 2 + 2

                        TopRight.Init {
                            id: topRightStatus

                            popupScreen: bar.modelData
                            popupRightMargin: rightCluster.outerMargin + powerButton.width + statusPowerCluster.spacing
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Power.Init {
                            id: powerButton

                            popupScreen: bar.modelData
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
