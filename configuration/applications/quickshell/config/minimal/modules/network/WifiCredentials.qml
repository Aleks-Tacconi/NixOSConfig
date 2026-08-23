pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"

/**
 * Keyboard-friendly credentials form for visible and hidden Wi-Fi networks.
 */
ColumnLayout {
    id: root

    required property bool hiddenMode
    required property bool busy
    property string networkName: ""
    property string errorText: ""
    property bool secured: true
    property bool showPassword: false

    signal submitted(string ssid, bool secured, string password)
    signal cancelled

    spacing: Theme.panelItemGap

    function focusInput() {
        if (root.hiddenMode)
            ssidInput.forceActiveFocus();
        else
            passwordInput.forceActiveFocus();
    }

    function clear() {
        ssidInput.text = "";
        passwordInput.text = "";
        root.showPassword = false;
        root.secured = true;
    }

    function submit() {
        root.submitted(root.hiddenMode ? ssidInput.text.trim() : root.networkName, root.secured, passwordInput.text);
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => root.focusInput());
    }
    onBusyChanged: {
        if (visible && !root.busy)
            Qt.callLater(() => root.focusInput());
    }

    Frame.PanelSectionHeader {
        Layout.fillWidth: true
        title: root.hiddenMode ? "Join hidden network" : "Connect"
        detail: root.hiddenMode ? "Manual" : root.networkName
    }

    Text {
        visible: root.hiddenMode
        text: "Network name"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelCaptionSize
    }

    Rectangle {
        visible: root.hiddenMode
        Layout.fillWidth: true
        implicitHeight: visible ? 42 : 0
        radius: Theme.surfaceRadius
        color: ssidInput.activeFocus ? Theme.panelSurfaceHover : Theme.panelSurface

        TextInput {
            id: ssidInput

            anchors {
                fill: parent
                leftMargin: Theme.gap * 3
                rightMargin: Theme.gap * 3
            }
            enabled: !root.busy
            color: Theme.fg
            selectionColor: Theme.red
            selectedTextColor: "#000000"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
            verticalAlignment: TextInput.AlignVCenter
            clip: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.cancelled();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.secured)
                        passwordInput.forceActiveFocus();
                    else
                        root.submit();
                    event.accepted = true;
                }
            }
        }
    }

    Text {
        visible: root.hiddenMode
        text: "Security"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelCaptionSize
    }

    RowLayout {
        visible: root.hiddenMode
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 38 : 0
        spacing: Theme.gap * 2

        Repeater {
            model: [{
                label: "WPA Personal",
                secured: true
            }, {
                label: "Open",
                secured: false
            }]

            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.surfaceRadius
                color: root.secured === modelData.secured ? Theme.panelSurfaceHover : Theme.panelSurface
                opacity: root.busy ? 0.45 : 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: root.secured === modelData.secured ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.busy
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.secured = modelData.secured
                }
            }
        }
    }

    Text {
        visible: root.secured
        text: "Password"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelCaptionSize
    }

    Rectangle {
        visible: root.secured
        Layout.fillWidth: true
        implicitHeight: visible ? 42 : 0
        radius: Theme.surfaceRadius
        color: passwordInput.activeFocus ? Theme.panelSurfaceHover : Theme.panelSurface

        TextInput {
            id: passwordInput

            anchors {
                fill: parent
                leftMargin: Theme.gap * 3
                rightMargin: 42
            }
            enabled: !root.busy
            color: Theme.fg
            selectionColor: Theme.red
            selectedTextColor: "#000000"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
            verticalAlignment: TextInput.AlignVCenter
            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
            clip: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.cancelled();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.submit();
                    event.accepted = true;
                }
            }
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: Theme.gap * 3
                verticalCenter: parent.verticalCenter
            }
            text: root.showPassword ? "󰈈" : "󰈉"
            color: revealArea.containsMouse ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
        }

        MouseArea {
            id: revealArea

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
            }
            width: 42
            enabled: !root.busy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.showPassword = !root.showPassword
        }
    }

    Text {
        visible: root.errorText.length > 0
        Layout.fillWidth: true
        text: root.errorText
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelCaptionSize
        wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.gap * 2

        Repeater {
            model: [{
                label: "Cancel",
                submit: false
            }, {
                label: root.busy ? "Connecting" : "Connect",
                submit: true
            }]

            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.surfaceRadius
                color: actionArea.containsMouse && !root.busy ? Theme.panelSurfaceHover : Theme.panelSurface
                opacity: root.busy ? 0.45 : 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    font.bold: modelData.submit
                }

                MouseArea {
                    id: actionArea

                    anchors.fill: parent
                    enabled: !root.busy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: modelData.submit ? root.submit() : root.cancelled()
                }
            }
        }
    }
}
