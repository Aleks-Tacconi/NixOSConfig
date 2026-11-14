pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../theme"
import "../frame" as Frame

/** Shared authentication surface used by both the lockscreen and greetd greeter. */
Item {
    id: root

    property string username: "aleks"
    property string wallpaperSource: ""
    property string errorMessage: ""
    property bool busy: false
    property bool showPowerActions: true
    property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")
    property string currentDate: Qt.formatDateTime(new Date(), "dddd, MMMM d")

    signal submitted(string password)

    function clearInput(): void {
        passwordInput.text = "";
    }

    function focusInput(): void {
        passwordInput.forceActiveFocus();
    }

    Component.onCompleted: root.focusInput()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            root.currentTime = Qt.formatDateTime(now, "HH:mm");
            root.currentDate = Qt.formatDateTime(now, "dddd, MMMM d");
        }
    }

    Process {
        id: powerProcess
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.onAccent

        Image {
            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            visible: root.wallpaperSource.length > 0
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.panelSectionGap * 1.5
        width: 340

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.displaySize * 1.6
                font.weight: Theme.emphasisWeight
                text: root.currentTime
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                text: root.currentDate
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.panelRowHeight + 8
                radius: Theme.surfaceRadius
                color: Theme.bg
                border.width: 1
                border.color: root.errorMessage.length > 0
                    ? Theme.batteryCritical
                    : (passwordInput.activeFocus ? Theme.focusBorder : Theme.popupBorder)

                TextInput {
                    id: passwordInput

                    anchors {
                        fill: parent
                        leftMargin: Theme.panelItemGap + 2
                        rightMargin: Theme.panelItemGap + 2
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    enabled: !root.busy
                    focus: true

                    onAccepted: {
                        if (root.busy || passwordInput.text.length === 0)
                            return;
                        const value = passwordInput.text;
                        passwordInput.text = "";
                        root.submitted(value);
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text.length === 0
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    text: root.busy ? "Authenticating..." : "Password"
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.errorMessage.length > 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.batteryCritical
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                text: root.errorMessage
            }
        }
    }

    RowLayout {
        visible: root.showPowerActions
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Theme.panelPadding * 1.5
        }
        spacing: Theme.panelItemGap

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
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        text: actionBtn.modelData.label
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        powerProcess.command = actionBtn.modelData.command;
                        powerProcess.running = true;
                    }
                }
            }
        }
    }
}
