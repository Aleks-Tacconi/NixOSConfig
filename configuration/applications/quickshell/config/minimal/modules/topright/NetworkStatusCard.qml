pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"

/**
 * Active network connection summary, live traffic rates, action banner, and confirmation prompt.
 */
ColumnLayout {
    id: root

    required property var service
    required property string mode
    required property var selectedNetwork
    readonly property bool editing: root.mode !== "list"
    readonly property bool confirming: root.mode === "confirm_switch" || root.mode === "confirm_disconnect"

    signal cancelConfirmed
    signal confirmTriggered

    spacing: Theme.panelItemGap

    function formatRate(bytesPerSecond) {
        return bytesPerSecond >= 1048576
            ? `${(bytesPerSecond / 1048576).toFixed(1)} MB/s`
            : `${Math.round(bytesPerSecond / 1024)} KB/s`;
    }

    function iconText() {
        if (root.service.networkType === "ethernet")
            return root.service.networkState === "connected" ? "󰈀" : "󰈂";
        return root.service.networkState === "connected" ? "󰤨" : "󰤭";
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: activeCardLayout.implicitHeight + Theme.gap * 2
        radius: Theme.cardRadius
        color: "transparent"

        ColumnLayout {
            id: activeCardLayout
            anchors { fill: parent; margins: Theme.gap }
            spacing: Theme.gap * 1.5

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gap * 2

                Text {
                    text: root.iconText()
                    color: root.service.networkState === "connected" ? Theme.fg : Theme.muted
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize + 4 }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true; elide: Text.ElideRight; color: Theme.fg; text: root.service.networkLabel
                        font { family: Theme.fontFamily; pixelSize: Theme.panelBodySize; weight: Theme.emphasisWeight }
                    }

                    Text {
                        Layout.fillWidth: true; elide: Text.ElideRight; color: Theme.muted
                        text: root.service.networkState === "connected"
                            ? `${root.service.networkType === "wifi" ? "Wi-Fi" : "Ethernet"} · ${root.service.interfaceName}`
                            : "No active connection"
                        font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize }
                    }
                }

                Rectangle {
                    id: disconnectButton
                    visible: root.service.networkState === "connected" && root.service.networkType === "wifi"
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: disconnectButtonText.implicitWidth + Theme.gap * 3; implicitHeight: 22
                    radius: Theme.surfaceRadius; enabled: !root.service.actionPending
                    color: disconnectMouse.containsMouse && enabled ? Theme.panelSurfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: disconnectButtonText
                        anchors.centerIn: parent; text: "Disconnect"
                        color: disconnectMouse.containsMouse ? Theme.red : Theme.muted
                        font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize; weight: Theme.emphasisWeight }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: disconnectMouse
                        anchors.fill: parent; hoverEnabled: true; enabled: disconnectButton.enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.service.disconnectWifi()
                    }
                }

                Rectangle {
                    visible: root.service.networkState === "connected" && root.service.networkType !== "wifi"
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: connectedText.implicitWidth + Theme.gap * 3; implicitHeight: 20
                    radius: Theme.surfaceRadius; color: Theme.panelSurfaceHover

                    Text { id: connectedText; anchors.centerIn: parent; text: "Active"; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                }
            }

            RowLayout {
                visible: root.service.networkState === "connected"
                Layout.fillWidth: true; spacing: Theme.gap * 2

                Item {
                    Layout.fillWidth: true; implicitHeight: 24
                    RowLayout {
                        anchors.centerIn: parent; spacing: Theme.gap * 1.5
                        Text { text: "↓"; color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                        Text { text: root.formatRate(root.service.downloadBytesPerSecond); color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                    }
                }

                Item {
                    Layout.fillWidth: true; implicitHeight: 24
                    RowLayout {
                        anchors.centerIn: parent; spacing: Theme.gap * 1.5
                        Text { text: "↑"; color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                        Text { text: root.formatRate(root.service.uploadBytesPerSecond); color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: !root.editing && root.service.actionPending && root.service.actionStatusText.length > 0
        Layout.fillWidth: true; implicitHeight: visible ? 34 : 0
        radius: Theme.surfaceRadius; color: Theme.panelSurface

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.gap * 2; rightMargin: Theme.gap * 2 }
            spacing: Theme.gap * 2

            Frame.PanelSpinner { Layout.preferredWidth: 14; Layout.preferredHeight: 14; spinnerSize: 14 }
            Text { Layout.fillWidth: true; text: root.service.actionStatusText; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize } elide: Text.ElideRight }

            Rectangle {
                Layout.preferredWidth: 52; Layout.preferredHeight: 24; radius: Theme.surfaceRadius
                color: cancelActionMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"
                Text { anchors.centerIn: parent; text: "Cancel"; color: cancelActionMouse.containsMouse ? Theme.fg : Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize } }
                MouseArea { id: cancelActionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.cancelAction() }
            }
        }
    }

    ColumnLayout {
        visible: root.confirming
        Layout.fillWidth: true; spacing: Theme.panelItemGap

        Frame.PanelGroupLabel {
            Layout.fillWidth: true
            title: root.mode === "confirm_disconnect" ? "Disconnect Wi-Fi" : "Switch network"
            detail: root.selectedNetwork?.ssid ?? ""
        }

        Rectangle {
            Layout.fillWidth: true; implicitHeight: confirmContent.implicitHeight + Theme.gap * 4
            radius: Theme.surfaceRadius; color: Theme.panelSurface

            ColumnLayout {
                id: confirmContent
                anchors { fill: parent; margins: Theme.gap * 2 }
                spacing: Theme.gap

                Text {
                    Layout.fillWidth: true; color: Theme.fg; wrapMode: Text.Wrap
                    text: root.mode === "confirm_disconnect"
                        ? `Disconnect from "${root.selectedNetwork?.ssid || root.service.networkLabel}"?`
                        : `Disconnect from "${root.service.networkLabel}" and switch to "${root.selectedNetwork?.ssid}"?`
                    font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize }
                }

                Text {
                    Layout.fillWidth: true; color: Theme.muted; wrapMode: Text.Wrap
                    text: root.mode === "confirm_disconnect" ? "Your current connection will be closed." : "Your active connection will be switched to this network."
                    font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: Theme.gap * 2

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 38; radius: Theme.surfaceRadius
                color: cancelConfirmMouse.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface
                Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize } }
                MouseArea { id: cancelConfirmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cancelConfirmed() }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 38; radius: Theme.surfaceRadius
                color: confirmBtnMouse.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface
                Text { anchors.centerIn: parent; text: root.mode === "confirm_disconnect" ? "Disconnect" : "Switch"; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize; weight: Theme.emphasisWeight } }
                MouseArea { id: confirmBtnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.confirmTriggered() }
            }
        }
    }
}
