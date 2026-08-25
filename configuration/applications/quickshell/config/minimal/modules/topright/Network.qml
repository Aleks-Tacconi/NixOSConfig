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
                    text: root.service.networkState === "connected"
                        ? `${root.service.networkType} · ${root.service.interfaceName} · ↓ ${root.formatRate(root.service.downloadBytesPerSecond)} · ↑ ${root.formatRate(root.service.uploadBytesPerSecond)}`
                        : "No active connection"
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                }
            }
        }

        ColumnLayout {
            visible: !root.editing
            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                title: "Available networks"
                detail: root.service.wifiEnabled
                    ? (root.service.scanPending ? "Scanning" : `${root.service.networks.length}`)
                    : "Wi-Fi off"
            }

            Item {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? (root.service.errorText.length > 0 ? 132 : 184) : 0

                Flickable {
                    id: networksScroll

                    anchors {
                        fill: parent
                        rightMargin: Theme.gap * 2
                    }
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

                Frame.PanelScrollIndicator {
                    anchors {
                        top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                        rightMargin: 1
                    }
                    flickable: networksScroll
                }
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

            Item {
                Layout.preferredHeight: Theme.panelSectionGap - Theme.panelItemGap
            }

            Column {
                id: networkActions

                Layout.fillWidth: true
                spacing: Theme.gap

                Frame.PanelActionRow {
                    width: networkActions.width
                    label: "Wi-Fi"
                    icon: root.service.wifiEnabled ? "󰤨" : "󰤭"
                    active: root.service.wifiEnabled
                    enabled: !root.service.actionPending && root.service.wifiInterface.length > 0
                    detailText: root.service.wifiEnabled ? "On" : "Off"
                    showTrailing: false
                    onClicked: root.service.setWifiEnabled(!root.service.wifiEnabled)
                }

                Frame.PanelActionRow {
                    width: networkActions.width
                    label: "Scan networks"
                    icon: "󰑐"
                    enabled: root.service.wifiEnabled && !root.service.scanPending && !root.service.actionPending
                    detailText: root.service.scanPending ? "Scanning" : ""
                    showTrailing: false
                    onClicked: root.service.requestScan(true)
                }

                Frame.PanelActionRow {
                    width: networkActions.width
                    label: "Join hidden network"
                    icon: "󰖩"
                    enabled: root.service.wifiEnabled && !root.service.actionPending
                    showTrailing: true
                    onClicked: root.showHidden()
                }

                Frame.PanelActionRow {
                    visible: ShellConfig.Config.network.tailscale
                    width: networkActions.width
                    label: "Tailscale VPN"
                    icon: "󰒍"
                    active: root.service.tailscaleConnected
                    enabled: !root.service.tailscalePending
                    detailText: root.service.tailscalePending ? "Working" : (root.service.tailscaleConnected ? "On" : "Off")
                    showTrailing: false
                    onClicked: root.service.toggleTailscale()
                }
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
