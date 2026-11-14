pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../frame" as Frame
import "../../theme"

/**
 * Top-bar power indicator with a click power menu.
 */
Frame.BarPillButton {
    id: root

    property var popupScreen: null
    property real popupRightMargin: Theme.gap * 4
    property real indicatorSize: Theme.panelRowHeight - Theme.gap * 2
    property real menuPadding: Theme.panelPadding
    property real actionButtonWidth: 220
    property real actionButtonHeight: Theme.panelRowHeight
    property real menuGap: Theme.gap
    property int revealDuration: 180
    property int closeDelay: Theme.popupDismissDelay
    property bool menuOpen: false

    readonly property bool indicatorActive: root.menuOpen || menuWindow.progress > 0
    readonly property var menuActions: [
        { label: "Shutdown", icon: "⏻", command: ["systemctl", "poweroff"] },
        { label: "Lock", icon: "", command: ["hyprlock"] },
        { label: "Suspend", icon: "󰒲", command: ["systemctl", "suspend"] },
        { label: "Reboot", icon: "󰜉", command: ["systemctl", "reboot"] },
        { label: "Logout", icon: "󰍃", command: ["hyprctl", "dispatch", "exit"] },
    ]

    width: root.indicatorSize
    active: root.menuOpen
    onClicked: root.menuOpen = !root.menuOpen

    Process {
        id: actionRunner
    }

    Timer {
        id: pendingActionTimer

        property var pendingCommand: null

        interval: 250
        repeat: false
        onTriggered: {
            if (pendingActionTimer.pendingCommand !== null) {
                actionRunner.command = pendingActionTimer.pendingCommand;
                actionRunner.running = true;
                pendingActionTimer.pendingCommand = null;
            }
        }
    }

    function runAction(command) {
        root.menuOpen = false;

        if (command && command.includes("suspend")) {
            pendingActionTimer.pendingCommand = command;
            pendingActionTimer.restart();
        } else {
            actionRunner.command = command;
            actionRunner.running = true;
        }
    }

    Text {
        anchors.centerIn: parent
        color: Theme.red
        opacity: root.indicatorActive ? 1 : 0.9
        font.family: Theme.iconFontFamily
        font.pixelSize: Theme.fontSize + 1
        text: ""
    }

    Frame.BarPopupWindow {
        id: menuWindow

        popupScreen: root.popupScreen
        requestedOpen: root.menuOpen
        namespace: "quickshell:powerMenu"
        edgeMargin: root.popupRightMargin
        panelWidth: root.actionButtonWidth + root.menuPadding * 2
        panelDepth: menuContent.implicitHeight + root.menuPadding * 2
        contentPadding: root.menuPadding
        duration: root.revealDuration
        closeDelay: root.closeDelay
        hoverLeaseDuration: 1200
        activatorMouseArea: root.mouseArea
        onDismissRequested: root.menuOpen = false

        ColumnLayout {
            id: menuContent

            readonly property bool readyToShow: menuWindow.effectiveOpen && menuWindow.progress > 0.96

            anchors.fill: parent
            visible: menuContent.readyToShow || menuContent.opacity > 0
            opacity: menuContent.readyToShow ? 1 : 0
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
                font.weight: Theme.emphasisWeight
                text: "Power Menu"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.menuGap

                Repeater {
                    model: root.menuActions

                    Frame.PanelActionRow {
                        id: actionRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: root.actionButtonHeight
                        horizontalPadding: 0
                        enabled: !pendingActionTimer.running && !actionRunner.running
                        icon: actionRow.modelData.icon
                        label: actionRow.modelData.label
                        showTrailing: false
                        onClicked: root.runAction(actionRow.modelData.command)
                    }
                }
            }
        }
    }
}
