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
    readonly property var availableNetworks: {
        const list = root.service.networks ?? [];
        if (root.service.networkState === "connected" && root.service.networkType === "wifi") {
            const currentLabel = root.service.networkLabel;
            return list.filter(net => !net.active && net.ssid !== currentLabel);
        }
        return list.filter(net => !net.active);
    }

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
        if (root.service.networkType === "ethernet")
            return root.service.networkState === "connected" ? "󰈀" : "󰈂";
        if (root.service.networkState !== "connected")
            return "󰤭";
        return "󰤨";
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
            return;
        }
        if (!network.supported) {
            root.service.openSettings();
            root.service.errorText = `Configuring ${network.ssid} in network settings...`;
            return;
        }
        if (root.service.networkState === "connected" && root.service.networkType === "wifi") {
            root.selectedNetwork = network;
            root.validationError = "";
            root.mode = "confirm_switch";
            return;
        }
        root.proceedWithConnect(network);
    }

    function proceedWithConnect(network) {
        if (network.requiresPassword && network.savedUuid.length === 0) {
            root.showPassword(network);
            return;
        }
        root.service.activate(network);
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
            credentials.clear();
            if (root.editing)
                root.closeEditor();
        }
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            Frame.PanelSectionHeader {
                Layout.fillWidth: true
                title: "Network"
                detail: root.stateText()
                detailColor: root.service.networkState === "connected" ? Theme.fg : Theme.muted
            }

            Rectangle {
                id: scanButton

                visible: !root.editing && root.service.wifiInterface.length > 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: Theme.surfaceRadius
                color: scanMouse.containsMouse && enabled ? Theme.panelSurfaceHover : "transparent"
                enabled: root.service.wifiEnabled && !root.service.scanPending && !root.service.actionPending
                opacity: enabled || root.service.scanPending ? 1 : 0.45

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    id: scanIcon

                    anchors.centerIn: parent
                    text: "󰑐"
                    color: (root.service.scanPending || (scanMouse.containsMouse && scanButton.enabled)) ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                RotationAnimation {
                    target: scanIcon
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 850
                    loops: Animation.Infinite
                    running: root.service.scanPending && root.visible
                    onRunningChanged: {
                        if (!running)
                            scanIcon.rotation = 0;
                    }
                }

                MouseArea {
                    id: scanMouse

                    anchors.fill: parent
                    enabled: scanButton.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.service.requestScan(true)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: activeCardLayout.implicitHeight + Theme.gap * 3
            radius: Theme.cardRadius
            color: Theme.panelSurface

            ColumnLayout {
                id: activeCardLayout
                anchors {
                    fill: parent
                    margins: Theme.gap * 2
                }
                spacing: Theme.gap * 1.5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap * 2

                    Text {
                        text: root.iconText()
                        color: root.service.networkState === "connected" ? Theme.fg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.service.networkLabel
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelBodySize
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.service.networkState === "connected"
                                ? `${root.service.networkType === "wifi" ? "Wi-Fi" : "Ethernet"} · ${root.service.interfaceName}`
                                : "No active connection"
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                        }
                    }

                    Rectangle {
                        id: disconnectButton
                        visible: root.service.networkState === "connected" && root.service.networkType === "wifi"
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: disconnectButtonText.implicitWidth + Theme.gap * 3
                        implicitHeight: 22
                        radius: Theme.surfaceRadius
                        color: disconnectMouse.containsMouse && enabled ? Theme.panelSurfaceHover : "transparent"
                        enabled: !root.service.actionPending

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: disconnectButtonText
                            anchors.centerIn: parent
                            text: "Disconnect"
                            color: disconnectMouse.containsMouse ? Theme.red : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                            font.bold: true

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }

                        MouseArea {
                            id: disconnectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: disconnectButton.enabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.service.disconnectWifi()
                        }
                    }

                    Rectangle {
                        visible: root.service.networkState === "connected" && root.service.networkType !== "wifi"
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: connectedText.implicitWidth + Theme.gap * 3
                        implicitHeight: 20
                        radius: Theme.surfaceRadius
                        color: Theme.panelSurfaceHover

                        Text {
                            id: connectedText
                            anchors.centerIn: parent
                            text: "Active"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                        }
                    }
                }

                RowLayout {
                    visible: root.service.networkState === "connected"
                    Layout.fillWidth: true
                    spacing: Theme.gap * 2

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Theme.surfaceRadius
                        color: Theme.bg2

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.gap * 1.5

                            Text {
                                text: "↓"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelCaptionSize
                            }

                            Text {
                                text: root.formatRate(root.service.downloadBytesPerSecond)
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelCaptionSize
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Theme.surfaceRadius
                        color: Theme.bg2

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.gap * 1.5

                            Text {
                                text: "↑"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelCaptionSize
                            }

                            Text {
                                text: root.formatRate(root.service.uploadBytesPerSecond)
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelCaptionSize
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            visible: !root.editing
            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Rectangle {
                visible: !root.editing && root.service.actionPending && root.service.actionStatusText.length > 0
                Layout.fillWidth: true
                implicitHeight: visible ? 34 : 0
                radius: Theme.surfaceRadius
                color: Theme.panelSurface

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Theme.gap * 2
                        rightMargin: Theme.gap * 2
                    }
                    spacing: Theme.gap * 2

                    Frame.PanelSpinner {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        spinnerSize: 14
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.service.actionStatusText
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 24
                        radius: Theme.surfaceRadius
                        color: cancelActionMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: cancelActionMouse.containsMouse ? Theme.fg : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                        }

                        MouseArea {
                            id: cancelActionMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.service.cancelAction()
                        }
                    }
                }
            }

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                title: "Available networks"
                detail: root.service.wifiEnabled
                    ? `${root.availableNetworks.length}`
                    : "Wi-Fi off"
            }

            Item {
                visible: root.service.wifiEnabled
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 184 : 0
                implicitHeight: Layout.preferredHeight

                Flickable {
                    id: networksScroll

                    anchors {
                        fill: parent
                        rightMargin: Theme.gap * 2
                    }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    pixelAligned: true
                    contentWidth: width
                    contentHeight: networkColumn.implicitHeight
                    interactive: contentHeight > height

                    onMovementStarted: scrollAnim.stop()
                    onMovementEnded: wheelHandler.targetY = contentY

                    WheelHandler {
                        id: wheelHandler
                        target: null
                        enabled: networksScroll.interactive
                        property real targetY: networksScroll.contentY

                        onWheel: event => {
                            const step = event.angleDelta.y !== 0
                                ? (event.angleDelta.y / 120) * 44
                                : event.pixelDelta.y;
                            if (step === 0)
                                return;

                            const maxY = Math.max(0, networksScroll.contentHeight - networksScroll.height);
                            const base = scrollAnim.running ? targetY : networksScroll.contentY;
                            targetY = Math.max(0, Math.min(maxY, base - step));

                            if (event.pixelDelta.y !== 0 && event.angleDelta.y === 0) {
                                scrollAnim.stop();
                                networksScroll.contentY = targetY;
                            } else {
                                scrollAnim.stop();
                                scrollAnim.to = targetY;
                                scrollAnim.start();
                            }
                        }
                    }

                    NumberAnimation {
                        id: scrollAnim
                        target: networksScroll
                        property: "contentY"
                        duration: 160
                        easing.type: Easing.OutQuad
                    }

                    Column {
                        id: networkColumn

                        width: parent.width
                        spacing: Theme.gap

                        Repeater {
                            model: root.availableNetworks

                            delegate: Network.WifiNetworkRow {
                                required property var modelData

                                width: networkColumn.width
                                network: modelData
                                interactive: !root.service.actionPending
                                pending: root.service.actionPending && root.service.actionNetworkBssid === modelData.bssid
                                onActivated: root.handleNetworkClick(modelData)
                            }
                        }

                        Item {
                            visible: root.availableNetworks.length === 0
                            width: parent.width
                            height: 184

                            Text {
                                anchors.centerIn: parent
                                text: root.service.scanPending ? "Scanning..." : "No visible networks"
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                            }
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
                implicitHeight: Layout.preferredHeight
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
                    busy: root.service.actionPending
                    enabled: !root.service.actionPending && root.service.wifiInterface.length > 0
                    detailText: root.service.wifiEnabled ? "On" : "Off"
                    showTrailing: false
                    onClicked: root.service.setWifiEnabled(!root.service.wifiEnabled)
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
                    busy: root.service.tailscalePending
                    enabled: !root.service.tailscalePending
                    detailText: root.service.tailscaleConnected ? "On" : "Off"
                    showTrailing: false
                    onClicked: root.service.toggleTailscale()
                }
            }
        }

        ColumnLayout {
            id: confirmationView
            visible: root.mode === "confirm_switch" || root.mode === "confirm_disconnect"
            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                title: root.mode === "confirm_disconnect" ? "Disconnect Wi-Fi" : "Switch network"
                detail: root.selectedNetwork?.ssid ?? ""
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: confirmContent.implicitHeight + Theme.gap * 4
                radius: Theme.surfaceRadius
                color: Theme.panelSurface

                ColumnLayout {
                    id: confirmContent
                    anchors {
                        fill: parent
                        margins: Theme.gap * 2
                    }
                    spacing: Theme.gap

                    Text {
                        Layout.fillWidth: true
                        text: root.mode === "confirm_disconnect"
                            ? `Disconnect from "${root.selectedNetwork?.ssid || root.service.networkLabel}"?`
                            : `Disconnect from "${root.service.networkLabel}" and switch to "${root.selectedNetwork?.ssid}"?`
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.mode === "confirm_disconnect"
                            ? "Your current connection will be closed."
                            : "Your active connection will be switched to this network."
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                        wrapMode: Text.Wrap
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gap * 2

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.surfaceRadius
                    color: cancelConfirmMouse.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                    }

                    MouseArea {
                        id: cancelConfirmMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeEditor()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.surfaceRadius
                    color: confirmBtnMouse.containsMouse ? (root.mode === "confirm_disconnect" ? Theme.red : Theme.panelSurfaceHover) : Theme.panelSurfaceHover

                    Text {
                        anchors.centerIn: parent
                        text: root.mode === "confirm_disconnect" ? "Disconnect" : "Switch"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        font.bold: true
                    }

                    MouseArea {
                        id: confirmBtnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.mode === "confirm_disconnect") {
                                const target = root.selectedNetwork;
                                root.closeEditor();
                                root.service.disconnectWifi(target);
                            } else {
                                const target = root.selectedNetwork;
                                root.mode = "list";
                                root.proceedWithConnect(target);
                            }
                        }
                    }
                }
            }
        }

        Network.WifiCredentials {
            id: credentials

            visible: root.mode === "password" || root.mode === "hidden"
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
