pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../frame" as Frame
import "../../theme"

/**
 * Top-right status cluster with audio, battery, network, and media popups.
 */
Item {
    id: root

    width: statusFrame.width
    height: Theme.barHeight

    required property var networkService
    property var popupScreen: null
    property real popupRightMargin: Theme.gap * 2
    property string openPopup: ""
    readonly property real audioPopupHeight: audioView.playerCount > 0 ? 540 + Theme.panelSectionGap : 360
    readonly property real networkPopupHeight: Math.min(540, networkView.implicitHeight + Theme.panelPadding * 2)
    readonly property bool audioOpen: root.openPopup === "audio"
    readonly property bool networkOpen: root.openPopup === "network"
    readonly property bool batteryOpen: root.openPopup === "battery"
    readonly property int audioPercent: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)
    readonly property bool audioMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    readonly property string networkIcon: root.iconForNetwork()
    readonly property var laptopBattery: BatteryService.laptopBattery
    readonly property bool hasBattery: root.laptopBattery !== null || BatteryService.sysfsBatteryPresent
    readonly property int batteryPercent: Math.round(root.laptopBattery !== null ? root.laptopBattery.percentage * 100 : BatteryService.sysfsBatteryPercentValue)
    readonly property string batteryIcon: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.max(0, Math.min(10, Math.floor(root.batteryPercent / 10)))]
    readonly property real batteryPanelHeight: batteryContent.implicitHeight + Theme.panelPadding * 2
    readonly property real mediaPopupRightOffset: Math.max(0, statusContent.width - mediaButton.x - mediaButton.width)
    readonly property real networkPopupRightOffset: Math.max(0, statusContent.width - networkButton.x - networkButton.width)

    onNetworkOpenChanged: {
        if (root.networkOpen)
            root.networkService.requestScan(root.networkService.networks.length === 0);
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    function iconForNetwork() {
        if (root.networkService.networkType === "ethernet")
            return root.networkService.networkState === "connected" ? "󰈀" : "󰈂";
        if (root.networkService.networkState !== "connected")
            return "󰤭";
        const networks = root.networkService.networks ?? [];
        const activeNetwork = networks.find(net => net.active) ?? networks.find(net => net.ssid === root.networkService.networkLabel);
        const signal = (activeNetwork && typeof activeNetwork.signal === "number") ? activeNetwork.signal : 100;
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
    }

    function formatPercent(percent) { return `${Math.max(0, Math.min(999, percent))}%`; }
    function setAudioPercent(percent) {
        const audio = Pipewire.defaultAudioSink?.audio;
        if (audio) audio.volume = Math.max(0, Math.min(1.5, percent / 100));
    }
    function adjustAudioPercent(delta) { root.setAudioPercent(root.audioPercent + delta); }
    function togglePopup(name) { root.openPopup = root.openPopup === name ? "" : name; }
    function closePopup(name) { if (root.openPopup === name) root.openPopup = ""; }

    Item {
        id: statusFrame
        anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        width: statusContent.implicitWidth

        Row {
            id: statusContent
            anchors { top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap / 2

            Frame.BarPillButton {
                id: mediaButton
                width: Theme.panelRowHeight + Theme.gap
                active: root.audioOpen
                onClicked: root.togglePopup("audio")
                onWheel: wheel => {
                    root.adjustAudioPercent(wheel.angleDelta.y > 0 ? 5 : -5);
                    wheel.accepted = true;
                }

                Text {
                    anchors.centerIn: parent
                    text: mediaButton.hovered || root.audioOpen ? root.formatPercent(root.audioPercent) : (root.audioMuted ? "󰖁" : "")
                    color: root.audioMuted ? Theme.muted : Theme.fg
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize + 1; bold: true }
                }
            }

            Frame.BarPillButton {
                id: networkButton
                width: Theme.panelRowHeight
                active: root.networkOpen
                onClicked: root.togglePopup("network")

                Text {
                    anchors.centerIn: parent
                    text: root.networkIcon
                    color: Theme.red
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize + 1; bold: true }
                }
            }

            Frame.BarPillButton {
                id: batteryButton
                visible: root.hasBattery
                width: visible ? Theme.panelRowHeight + Theme.gap : 0
                active: root.batteryOpen
                onClicked: root.togglePopup("battery")

                Text {
                    anchors.centerIn: parent
                    text: batteryButton.hovered ? root.formatPercent(root.batteryPercent) : root.batteryIcon
                    color: root.batteryPercent < 10 ? Theme.batteryCritical : Theme.fg
                    font { family: Theme.fontFamily; pixelSize: batteryButton.hovered ? Theme.fontSize + 1 : Theme.iconSize + Theme.gap / 2; bold: true }
                }
            }
        }
    }

    Frame.BarPopupWindow {
        id: mediaWindow
        popupScreen: root.popupScreen
        requestedOpen: root.audioOpen
        namespace: "quickshell:topRightAudioPullout"
        alignEdge: "right"
        edgeMargin: root.popupRightMargin
        panelWidth: 360
        panelDepth: root.audioPopupHeight
        activatorMouseArea: mediaButton.mouseArea
        hoverBridgeActivator: mediaButton
        hoverBridgeX: Math.max(0, width - root.mediaPopupRightOffset - mediaButton.width)
        onDismissRequested: root.closePopup("audio")

        Media { id: audioView; anchors.fill: parent }
    }

    Frame.BarPopupWindow {
        id: networkWindow
        popupScreen: root.popupScreen
        requestedOpen: root.networkOpen
        namespace: "quickshell:topRightNetworkPullout"
        alignEdge: "right"
        edgeMargin: root.popupRightMargin
        panelWidth: 360
        panelDepth: root.networkPopupHeight
        activatorMouseArea: networkButton.mouseArea
        hoverBridgeActivator: networkButton
        hoverBridgeX: Math.max(0, width - root.networkPopupRightOffset - networkButton.width)
        onDismissRequested: root.closePopup("network")

        Network { id: networkView; anchors.fill: parent; open: root.networkOpen; service: root.networkService }
    }

    Frame.BarPopupWindow {
        id: batteryWindow
        popupScreen: root.popupScreen
        requestedOpen: root.hasBattery && root.batteryOpen
        forceClose: !root.hasBattery
        namespace: "quickshell:topRightBatteryPullout"
        alignEdge: "right"
        edgeMargin: root.popupRightMargin
        panelWidth: 340
        panelDepth: root.batteryPanelHeight
        activatorMouseArea: batteryButton.mouseArea
        hoverBridgeActivator: batteryButton
        hoverBridgeX: Math.max(0, width - batteryButton.width)
        onDismissRequested: root.closePopup("battery")

        Column {
            id: batteryContent
            anchors.fill: parent

            Battery {
                width: parent.width
                device: root.laptopBattery
                fallbackPercent: BatteryService.sysfsBatteryPercentValue
                fallbackState: BatteryService.sysfsBatteryState
                fallbackSecondsRemaining: BatteryService.sysfsBatterySecondsRemainingValue
                fallbackRateWatts: BatteryService.sysfsBatteryRateWattsValue
            }
        }
    }
}
