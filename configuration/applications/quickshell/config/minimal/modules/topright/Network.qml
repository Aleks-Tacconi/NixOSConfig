pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../network" as Network
import "../../theme"
import "../.." as ShellConfig

/**
 * Interactive network status, Wi-Fi picker, and credentials flow.
 */
Item {
    id: root

    required property bool open
    required property var service
    property string mode: "list"
    property var selectedNetwork: null
    property string validationError: ""
    readonly property bool editing: root.mode !== "list"

    implicitHeight: content.implicitHeight

    function formatRate(bytesPerSecond) {
        if (bytesPerSecond >= 1048576)
            return `${(bytesPerSecond / 1048576).toFixed(1)} MB/s`;
        return `${Math.round(bytesPerSecond / 1024)} KB/s`;
    }

    function stateText() {
        if (root.service.networkState === "connected")
            return "Connected";
        if (root.service.networkState === "unavailable")
            return "Unavailable";
        return "Disconnected";
    }

    function iconText() {
        if (root.service.networkState !== "connected")
            return "󰤭";
        return root.service.networkType === "ethernet" ? "󰈀" : "󰤨";
    }

    function showPassword(network) {
        root.selectedNetwork = network;
        root.validationError = "";
        root.mode = "password";
    }

    function showHidden() {
        root.selectedNetwork = null;
        root.validationError = "";
        credentials.clear();
        root.mode = "hidden";
    }

    function closeEditor() {
        credentials.clear();
        root.selectedNetwork = null;
        root.validationError = "";
        root.mode = "list";
        root.service.clearError();
    }

    function submitCredentials(ssid, secured, password) {
        if (ssid.length === 0) {
            root.validationError = "Enter a network name";
            return;
        }
        if (secured && password.length < 8) {
            root.validationError = "WPA passwords require at least 8 characters";
            return;
        }
        root.validationError = "";
        if (root.mode === "hidden")
            root.service.activateHidden(ssid, secured, password);
        else
            root.service.activateWithPassword(root.selectedNetwork, password);
        credentials.clear();
    }

    onOpenChanged: {
        if (!root.open && root.editing)
            root.closeEditor();
    }

    Connections {
        target: root.service

        function onPasswordRequested(network) {
            if (root.open)
                root.showPassword(network);
        }

        function onActionSucceeded() {
            if (root.editing)
                root.closeEditor();
        }
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Network"
            detail: root.stateText()
            detailColor: root.service.networkState === "connected" ? Theme.fg : Theme.muted
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            Text {
                Layout.preferredWidth: Theme.fontSize + 10
                text: root.iconText()
                color: root.service.networkState === "connected" ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.service.networkLabel
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                }

                Text {
                    Layout.fillWidth: true
                    text: root.service.interfaceName.length > 0 ? `${root.service.interfaceName} · ${root.service.networkType}` : "No active interface"
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                }
            }

            ColumnLayout {
                spacing: 0

                Text {
                    text: `↓ ${root.formatRate(root.service.downloadBytesPerSecond)}`
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                }

                Text {
                    text: `↑ ${root.formatRate(root.service.uploadBytesPerSecond)}`
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                }
            }
        }

        Frame.PanelDivider {
            Layout.fillWidth: true
        }

        ColumnLayout {
            visible: !root.editing
            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Frame.PanelActionRow {
                Layout.fillWidth: true
                label: "Wi-Fi"
                icon: root.service.wifiEnabled ? "󰤨" : "󰤭"
                active: root.service.wifiEnabled
                enabled: !root.service.actionPending && root.service.wifiInterface.length > 0
                detailText: root.service.wifiEnabled ? "On" : "Off"
                trailingText: ""
                onClicked: root.service.setWifiEnabled(!root.service.wifiEnabled)
            }

            Frame.PanelSectionHeader {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                title: "Available networks"
                detail: root.service.scanPending ? "Scanning" : `${root.service.networks.length}`
            }

            Item {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 192 : 0

                Flickable {
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: networkColumn.implicitHeight
                    interactive: contentHeight > height

                    Column {
                        id: networkColumn

                        width: parent.width
                        spacing: Theme.gap

                        Repeater {
                            model: root.service.networks

                            delegate: Network.WifiNetworkRow {
                                required property var modelData

                                width: networkColumn.width
                                network: modelData
                                interactive: !root.service.actionPending
                                pending: root.service.actionPending && root.service.actionNetworkBssid === modelData.bssid
                                onActivated: root.service.activate(modelData)
                            }
                        }

                        Text {
                            visible: root.service.networks.length === 0
                            width: parent.width
                            height: 54
                            text: root.service.scanPending ? "Scanning for networks..." : "No visible networks"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Frame.PanelActionRow {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                label: "Scan again"
                icon: "󰑐"
                enabled: !root.service.scanPending && !root.service.actionPending
                trailingText: ""
                onClicked: root.service.requestScan(true)
            }

            Frame.PanelActionRow {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                label: "Join hidden network"
                icon: "󰖩"
                enabled: !root.service.actionPending
                onClicked: root.showHidden()
            }

            Text {
                visible: root.service.errorText.length > 0
                Layout.fillWidth: true
                text: root.service.errorText
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                wrapMode: Text.Wrap
            }

            Frame.PanelDivider {
                visible: ShellConfig.Config.network.tailscale
                Layout.fillWidth: true
            }

            Frame.PanelActionRow {
                visible: ShellConfig.Config.network.tailscale
                Layout.fillWidth: true
                label: "Tailscale"
                icon: "󰒍"
                active: root.service.tailscaleConnected
                enabled: !root.service.tailscalePending
                detailText: root.service.tailscalePending ? "Working" : (root.service.tailscaleConnected ? "On" : "Off")
                onClicked: root.service.toggleTailscale()
            }
        }

        Network.WifiCredentials {
            id: credentials

            visible: root.editing
            Layout.fillWidth: true
            hiddenMode: root.mode === "hidden"
            networkName: root.selectedNetwork?.ssid ?? ""
            busy: root.service.actionPending
            errorText: root.validationError.length > 0 ? root.validationError : root.service.errorText
            onCancelled: root.closeEditor()
            onSubmitted: (ssid, secured, password) => root.submitCredentials(ssid, secured, password)
        }
    }
}
