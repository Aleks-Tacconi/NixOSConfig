pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
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
    readonly property real networkPopupHeight: 510
    readonly property bool audioOpen: root.openPopup === "audio"
    readonly property bool networkOpen: root.openPopup === "network"
    readonly property bool batteryOpen: root.openPopup === "battery"
    readonly property int audioPercent: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)
    readonly property bool audioMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    readonly property string networkIcon: iconForNetwork()
    readonly property var laptopBattery: BatteryService.laptopBattery
    readonly property bool hasBattery: laptopBattery !== null || BatteryService.sysfsBatteryPresent
    readonly property int batteryPercent: Math.round(laptopBattery !== null ? laptopBattery.percentage * 100 : BatteryService.sysfsBatteryPercentValue)
    readonly property string batteryIcon: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.max(0, Math.min(10, Math.floor(root.batteryPercent / 10)))]
    readonly property real batteryPanelHeight: batteryContent.implicitHeight + Theme.panelPadding * 2

    onNetworkOpenChanged: {
        if (root.networkOpen)
            root.networkService.requestScan(root.networkService.networks.length === 0);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function iconForNetwork() {
        if (root.networkService.networkType === "ethernet")
            return root.networkService.networkState === "connected" ? "󰈀" : "󰈂";

        if (root.networkService.networkState !== "connected")
            return "󰤭";

        const networks = root.networkService.networks ?? [];
        const activeNetwork = networks.find(net => net.active) ?? networks.find(net => net.ssid === root.networkService.networkLabel);
        const signal = (activeNetwork && typeof activeNetwork.signal === "number") ? activeNetwork.signal : 100;

        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function formatPercent(percent) {
        return `${Math.max(0, Math.min(999, percent))}%`;
    }

    function setAudioPercent(percent) {
        const audio = Pipewire.defaultAudioSink?.audio;

        if (!audio)
            return;

        audio.volume = Math.max(0, Math.min(1.5, percent / 100));
    }

    function adjustAudioPercent(delta) {
        root.setAudioPercent(root.audioPercent + delta);
    }

    function segmentRightMargin(item) {
        const position = item.mapToItem(statusFrame, 0, 0);

        return root.popupRightMargin + Math.max(0, statusFrame.width - position.x - item.width);
    }

    function togglePopup(name) {
        root.openPopup = root.openPopup === name ? "" : name;
    }

    function closePopup(name) {
        if (root.openPopup === name)
            root.openPopup = "";
    }

    Item {
        id: statusFrame

        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: statusContent.implicitWidth

        Row {
            id: statusContent

            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            spacing: Theme.gap / 2

            Item {
                id: audioSegment

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                z: audioTrigger.containsMouse ? 1 : 0
                width: Theme.panelRowHeight + Theme.gap

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                    }
                    height: Theme.panelRowHeight
                    color: audioTrigger.containsMouse || root.audioOpen ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: audioTrigger.containsMouse || root.audioOpen
                        ? root.formatPercent(root.audioPercent)
                        : (root.audioMuted ? "󰖁" : "")
                    color: root.audioMuted ? Theme.muted : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                }

                MouseArea {
                    id: audioTrigger

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        bottomMargin: -Theme.popupGap
                        left: parent.left
                        right: parent.right
                    }
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePopup("audio")

                    onWheel: wheel => {
                        root.adjustAudioPercent(wheel.angleDelta.y > 0 ? 5 : -5);
                        wheel.accepted = true;
                    }
                }
            }

            Item {
                id: networkSegment

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                z: networkTrigger.containsMouse ? 1 : 0
                width: Theme.panelRowHeight

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                    }
                    height: Theme.panelRowHeight
                    color: networkTrigger.containsMouse || root.networkOpen ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Row {
                    id: networkRow

                    anchors.centerIn: parent
                    spacing: Theme.gap * 2

                    Text {
                        text: root.networkIcon
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                    }
                }

                MouseArea {
                    id: networkTrigger

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        bottomMargin: -Theme.popupGap
                        left: parent.left
                        right: parent.right
                    }
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePopup("network")
                }
            }

            Item {
                id: batterySegment

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                z: batteryTrigger.containsMouse ? 1 : 0
                visible: root.hasBattery
                width: visible ? Theme.panelRowHeight + Theme.gap : 0

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                    }
                    height: Theme.panelRowHeight
                    color: batteryTrigger.containsMouse || root.batteryOpen ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: batteryTrigger.containsMouse
                        ? root.formatPercent(root.batteryPercent)
                        : root.batteryIcon
                    color: root.batteryPercent < 10 ? Theme.batteryCritical : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: batteryTrigger.containsMouse ? Theme.fontSize + 1 : Theme.iconSize + Theme.gap / 2
                    font.bold: true
                }

                MouseArea {
                    id: batteryTrigger

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        bottomMargin: -Theme.popupGap
                        left: parent.left
                        right: parent.right
                    }
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePopup("battery")
                }
            }
        }
    }

    PanelWindow {
        id: audioPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.audioOpen || audioPanel.progress > 0
        implicitWidth: audioPanel.length + audioPanel.curveRadius
        implicitHeight: audioPanel.depth + audioPanel.curveRadius
        mask: Region {
            item: audioPopupHost
        }

        WlrLayershell.namespace: "quickshell:topRightAudioPullout"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.audioOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.segmentRightMargin(audioSegment)
        }

        Item {
            id: audioPopupHost

            anchors.fill: parent
            clip: false
            visible: audioPopupWindow.visible

            Frame.PulloutPanel {
                id: audioPanel

                corner: "topRight"
                requestedOpen: root.audioOpen
                activatorMouseArea: audioTrigger
                dismissOnExit: false
                clickDismiss: true
                onDismissRequested: root.closePopup("audio")

                length: 360
                depth: root.audioPopupHeight
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    right: parent.right
                }

                Item {
                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }
                    clip: true

                    Media {
                        id: audioView

                        anchors.fill: parent
                    }
                }
            }
        }
    }

    PanelWindow {
        id: networkPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.networkOpen || networkPanel.progress > 0
        implicitWidth: networkPanel.length + networkPanel.curveRadius
        implicitHeight: networkPanel.depth + networkPanel.curveRadius
        mask: Region {
            item: networkPopupHost
        }

        WlrLayershell.namespace: "quickshell:topRightNetworkPullout"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.networkOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.segmentRightMargin(networkSegment)
        }

        Item {
            id: networkPopupHost

            anchors.fill: parent
            clip: false
            visible: networkPopupWindow.visible

            Frame.PulloutPanel {
                id: networkPanel

                corner: "topRight"
                requestedOpen: root.networkOpen
                activatorMouseArea: networkTrigger
                dismissOnExit: false
                clickDismiss: true
                onDismissRequested: root.closePopup("network")

                length: 360
                depth: root.networkPopupHeight
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    right: parent.right
                }

                Item {
                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }
                    clip: true

                    Network {
                        id: networkView

                        anchors.fill: parent
                        open: root.networkOpen
                        service: root.networkService
                    }
                }
            }
        }
    }

    PanelWindow {
        id: batteryPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.hasBattery && (root.batteryOpen || batteryPanel.progress > 0)
        implicitWidth: batteryPanel.length + batteryPanel.curveRadius
        implicitHeight: batteryPanel.depth + batteryPanel.curveRadius
        mask: Region {
            item: batteryPopupHost
        }

        WlrLayershell.namespace: "quickshell:topRightBatteryPullout"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.batteryOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.segmentRightMargin(batterySegment)
        }

        Item {
            id: batteryPopupHost

            anchors.fill: parent
            clip: false
            visible: batteryPopupWindow.visible

            Frame.PulloutPanel {
                id: batteryPanel

                corner: "topRight"
                requestedOpen: root.batteryOpen
                activatorMouseArea: batteryTrigger
                dismissOnExit: false
                clickDismiss: true
                onDismissRequested: root.closePopup("battery")

                length: 340
                depth: root.batteryPanelHeight
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    right: parent.right
                }

                Column {
                    id: batteryContent

                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }

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
    }
}
