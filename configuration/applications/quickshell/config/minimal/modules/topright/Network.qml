pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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
    readonly property var availableNetworks: {
        const list = root.service.networks ?? [];
        if (root.service.networkState === "connected" && root.service.networkType === "wifi")
            return list.filter(net => !net.active && net.ssid !== root.service.networkLabel);
        return list.filter(net => !net.active);
    }

    implicitHeight: content.implicitHeight

    function stateText() {
        if (root.service.networkState === "connected") return "Connected";
        if (root.service.networkState === "unavailable") return "Unavailable";
        return "Disconnected";
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
    function handleNetworkClick(network) {
        if (network.active) {
            root.selectedNetwork = network;
            root.validationError = "";
            root.mode = "confirm_disconnect";
        } else if (!network.supported) {
            root.service.openSettings();
            root.service.errorText = `Configuring ${network.ssid} in network settings...`;
        } else if (root.service.networkState === "connected" && root.service.networkType === "wifi") {
            root.selectedNetwork = network;
            root.validationError = "";
            root.mode = "confirm_switch";
        } else {
            root.proceedWithConnect(network);
        }
    }
    function proceedWithConnect(network) {
        if (network.requiresPassword && network.savedUuid.length === 0) root.showPassword(network);
        else root.service.activate(network);
    }
    function confirmNetworkAction() {
        const target = root.selectedNetwork;
        if (root.mode === "confirm_disconnect") {
            root.closeEditor();
            root.service.disconnectWifi(target);
        } else {
            root.mode = "list";
            root.proceedWithConnect(target);
        }
    }
    function submitCredentials(ssid, secured, password) {
        if (ssid.length === 0) root.validationError = "Enter a network name";
        else if (secured && password.length < 8) root.validationError = "WPA passwords require at least 8 characters";
        else {
            root.validationError = "";
            if (root.mode === "hidden") root.service.activateHidden(ssid, secured, password);
            else root.service.activateWithPassword(root.selectedNetwork, password);
        }
    }

    Component.onCompleted: root.service.setTrafficVisible(root, root.open)
    Component.onDestruction: root.service.setTrafficVisible(root, false)
    onOpenChanged: {
        root.service.setTrafficVisible(root, root.open);
        if (!root.open && root.editing) root.closeEditor();
    }

    Connections {
        target: root.service
        function onPasswordRequested(network) { if (root.open) root.showPassword(network); }
        function onActionSucceeded() {
            credentials.clear();
            if (root.editing) root.closeEditor();
        }
    }

    ColumnLayout {
        id: content
        width: parent.width; spacing: Theme.panelItemGap

        RowLayout {
            Layout.fillWidth: true; spacing: Theme.gap

            Frame.PanelSectionHeader {
                Layout.fillWidth: true; title: "Network"; detail: root.stateText()
                detailColor: root.service.networkState === "connected" ? Theme.fg : Theme.muted
            }

            Rectangle {
                id: scanButton
                visible: !root.editing && root.service.wifiInterface.length > 0
                Layout.preferredWidth: 24; Layout.preferredHeight: 24; Layout.alignment: Qt.AlignVCenter
                radius: Theme.surfaceRadius
                color: scanMouse.containsMouse && enabled ? Theme.panelSurfaceHover : "transparent"
                enabled: root.service.wifiEnabled && !root.service.scanPending && !root.service.actionPending
                opacity: enabled || root.service.scanPending ? 1 : 0.45
                Behavior on color { ColorAnimation { duration: 120 } }

                Frame.PanelSpinner { anchors.centerIn: parent; running: root.service.scanPending && root.visible; spinnerSize: Theme.iconSize }
                MouseArea { id: scanMouse; anchors.fill: parent; enabled: scanButton.enabled; hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.service.requestScan(true) }
            }
        }

        NetworkStatusCard {
            Layout.fillWidth: true; service: root.service; mode: root.mode; selectedNetwork: root.selectedNetwork
            onCancelConfirmed: root.closeEditor()
            onConfirmTriggered: root.confirmNetworkAction()
        }

        ColumnLayout {
            visible: !root.editing
            Layout.fillWidth: true; spacing: Theme.panelItemGap

            Frame.PanelGroupLabel { Layout.fillWidth: true; title: "Available networks"; detail: root.service.wifiEnabled ? "" : "Wi-Fi off" }

            Item {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true; Layout.preferredHeight: visible ? 184 : 0; implicitHeight: Layout.preferredHeight

                Flickable {
                    id: networksScroll
                    anchors { fill: parent; rightMargin: Theme.gap * 2 }
                    clip: true; pixelAligned: true; boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
                    contentWidth: width; contentHeight: networkColumn.implicitHeight; interactive: contentHeight > height

                    Column {
                        id: networkColumn
                        width: parent.width; spacing: Theme.gap

                        Repeater {
                            model: ScriptModel { values: root.availableNetworks }

                            delegate: Network.WifiNetworkRow {
                                id: networkDelegate
                                required property var modelData
                                width: networkColumn.width; network: networkDelegate.modelData; interactive: !root.service.actionPending
                                pending: root.service.actionPending && root.service.actionNetworkBssid === networkDelegate.modelData.bssid
                                onActivated: root.handleNetworkClick(networkDelegate.modelData)
                            }
                        }

                        Item {
                            visible: root.availableNetworks.length === 0
                            width: parent.width; height: 184
                            Text { anchors.centerIn: parent; text: root.service.scanPending ? "Scanning..." : "No visible networks"; color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.panelMetaSize } }
                        }
                    }
                }

                Frame.PanelScrollIndicator { anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: 1 } flickable: networksScroll }
            }

            Text {
                visible: root.service.errorText.length > 0 || root.service.tailscaleError.length > 0
                Layout.fillWidth: true; color: Theme.fg; wrapMode: Text.Wrap
                text: [root.service.errorText, root.service.tailscaleError].filter(text => text.length > 0).join("\n")
                font { family: Theme.fontFamily; pixelSize: Theme.panelCaptionSize }
            }

            Item { Layout.preferredHeight: Theme.panelSectionGap - Theme.panelItemGap; implicitHeight: Layout.preferredHeight }

            Column {
                id: networkActions
                Layout.fillWidth: true; spacing: Theme.gap

                Frame.PanelActionRow {
                    width: networkActions.width; label: "Wi-Fi"; icon: root.service.wifiEnabled ? "󰤨" : "󰤭"
                    active: root.service.wifiEnabled; busy: root.service.actionPending
                    enabled: !root.service.actionPending && root.service.wifiInterface.length > 0
                    detailText: root.service.wifiEnabled ? "On" : "Off"; showTrailing: false
                    onClicked: root.service.setWifiEnabled(!root.service.wifiEnabled)
                }

                Frame.PanelActionRow {
                    width: networkActions.width; label: "Join hidden network"; icon: "󰖩"
                    enabled: root.service.wifiEnabled && !root.service.actionPending; showTrailing: true
                    onClicked: root.showHidden()
                }

                Frame.PanelActionRow {
                    visible: ShellConfig.Config.network.tailscale
                    width: networkActions.width; label: "Tailscale VPN"; icon: "󰒍"
                    active: root.service.tailscaleConnected; busy: root.service.tailscalePending
                    enabled: !root.service.tailscalePending; detailText: root.service.tailscaleConnected ? "On" : "Off"; showTrailing: false
                    onClicked: root.service.toggleTailscale()
                }
            }
        }

        Network.WifiCredentials {
            id: credentials
            visible: root.mode === "password" || root.mode === "hidden"
            Layout.fillWidth: true; hiddenMode: root.mode === "hidden"
            networkName: root.selectedNetwork?.ssid ?? ""; busy: root.service.actionPending
            errorText: root.validationError.length > 0 ? root.validationError : root.service.errorText
            onCancelled: root.closeEditor()
            onSubmitted: (ssid, secured, password) => root.submitCredentials(ssid, secured, password)
        }
    }
}
