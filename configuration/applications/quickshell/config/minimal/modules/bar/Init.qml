pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../dock" as Dock
import "../frame" as Frame
import "../power" as Power
import "../topleft/" as TopLeft
import "../topright/" as TopRight

/**
 * Top bar shell coordinator for every screen.
 */
Scope {
    id: root

    property var notificationCenter: null
    required property var networkService

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            readonly property real sideWidth: Math.max(0, (bar.width - workspaceViewport.width) / 2 - Theme.gap * 8)

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

            Frame.PanelSurface {
                anchors.fill: parent
                color: Theme.bg
                radius: 0
                framed: false


                Row {
                    id: leftCluster

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: Theme.gap * 4
                    }
                    spacing: Theme.gap * 6

                    TopLeft.Init {
                        id: leftStatus
                        maxWidth: Math.max(0, bar.sideWidth - Theme.panelRowHeight * 2 - leftCluster.spacing)
                        popupScreen: bar.modelData
                        notificationCenter: root.notificationCenter
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                    }

                    AppMenu {
                        id: appMenu

                        popupScreen: bar.modelData
                        parentWindow: bar
                        popupLeftMargin: leftCluster.x + appMenu.x - Theme.gap * 2
                        maxWidth: Math.max(0, bar.sideWidth - leftStatus.width - leftCluster.spacing)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Flickable {
                    id: workspaceViewport

                    anchors.centerIn: parent
                    width: Math.min(workspaces.implicitWidth, bar.width * 0.24)
                    height: Theme.barHeight
                    contentWidth: workspaces.implicitWidth
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    Workspaces {
                        id: workspaces
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: rightCluster

                    readonly property real outerMargin: Theme.gap * 4

                    function trailingWidth(item) {
                        return rightCluster.width - item.x - item.width;
                    }

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                        rightMargin: rightCluster.outerMargin
                    }

                    spacing: Theme.gap * 6

                    Dock.Init {
                        id: dock

                        popupScreen: bar.modelData
                        maxWidth: Math.max(0, Math.min(300, bar.sideWidth - systemCluster.width - rightCluster.spacing))
                        popupRightMargin: rightCluster.outerMargin + rightCluster.trailingWidth(dock)
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                    }

                    Row {
                        id: systemCluster

                        function trailingWidth(item) {
                            return systemCluster.width - item.x - item.width;
                        }

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        spacing: Theme.gap * 4

                        TopRight.Init {
                            id: topRightStatus

                            popupScreen: bar.modelData
                            popupRightMargin: rightCluster.outerMargin + systemCluster.trailingWidth(topRightStatus)
                            networkService: root.networkService
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                            }
                        }

                        Power.Init {
                            id: powerButton

                            popupScreen: bar.modelData
                            popupRightMargin: rightCluster.outerMargin + systemCluster.trailingWidth(powerButton)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
