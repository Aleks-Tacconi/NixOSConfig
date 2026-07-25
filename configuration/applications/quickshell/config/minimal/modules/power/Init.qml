pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Top-bar power indicator with a click power menu.
 */
Item {
    id: root

    property var popupScreen: null
    property real indicatorSize: 24
    property real menuPadding: Theme.panelPadding
    property real actionButtonWidth: 220
    property real actionButtonHeight: Theme.panelRowHeight
    property real menuGap: Theme.gap
    property real menuCurveRadius: 16
    property int revealDuration: 180
    property int closeDelay: 200
    property bool menuOpen: false
    property real menuProgress: 0

    readonly property bool indicatorActive: menuOpen || menuProgress > 0
    readonly property var menuActions: [
        {
            label: "Shutdown",
            icon: "⏻",
            command: ["systemctl", "poweroff"]
        },
        {
            label: "Lock",
            icon: "",
            command: ["hyprlock"]
        },
        {
            label: "Suspend",
            icon: "󰒲",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Reboot",
            icon: "󰜉",
            command: ["systemctl", "reboot"]
        },
        {
            label: "Logout",
            icon: "󰍃",
            command: ["hyprctl", "dispatch", "exit"]
        },
    ]

    readonly property real menuWidth: root.actionButtonWidth + root.menuPadding * 2
    readonly property real menuHeight: menuContent.implicitHeight + root.menuPadding * 2

    width: root.indicatorSize
    height: 28

    Process {
        id: actionRunner
    }

    function runAction(command) {
        actionRunner.command = command;
        actionRunner.running = true;
    }

    Text {
        anchors.centerIn: parent
        color: Theme.red
        opacity: root.indicatorActive ? 1 : 0.9
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
        text: ""
    }

    MouseArea {
        id: indicatorMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }

    PanelWindow {
        id: menuWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.menuOpen || menuPanel.progress > 0
        implicitWidth: menuPanel.length + menuPanel.curveRadius
        implicitHeight: menuPanel.depth + menuPanel.curveRadius

        mask: Region {
            item: menuHost
        }

        WlrLayershell.namespace: "quickshell:powerMenu"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: Theme.gap * 4
        }

        Item {
            id: menuHost

            anchors.fill: parent
            clip: false
            visible: menuWindow.visible

            Frame.PulloutPanel {
                id: menuPanel

                corner: "topRight"
                requestedOpen: root.menuOpen
                activatorMouseArea: indicatorMouse
                dismissOnExit: true
                closeDelay: root.closeDelay
                hoverLeaseDuration: 1200
                duration: root.revealDuration
                length: root.menuWidth
                depth: root.menuHeight
                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                onProgressChanged: root.menuProgress = menuPanel.progress
                onDismissRequested: root.menuOpen = false

                anchors {
                    top: parent.top
                    right: parent.right
                }

                ColumnLayout {
                    id: menuContent

                    readonly property bool readyToShow: menuPanel.effectiveOpen && menuPanel.progress > 0.96

                    anchors {
                        fill: parent
                        margins: root.menuPadding
                    }
                    visible: readyToShow || opacity > 0
                    opacity: readyToShow ? 1 : 0
                    spacing: Theme.panelItemGap

                    Behavior on opacity {
                        NumberAnimation {
                            duration: menuContent.readyToShow ? 90 : 45
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelTitleSize
                        font.bold: true
                        text: "Power Menu"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.menuGap

                        Repeater {
                            model: root.menuActions

                            Frame.PanelActionRow {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredHeight: root.actionButtonHeight
                                horizontalPadding: 0
                                icon: modelData.icon
                                label: modelData.label
                                showTrailing: false
                                onClicked: root.runAction(modelData.command)
                            }
                        }
                    }
                }
            }
        }
    }
}
