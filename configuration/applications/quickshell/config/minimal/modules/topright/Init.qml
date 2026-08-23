pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

Item {
    id: root

    width: statusFrame.width
    height: Theme.barHeight

    required property var networkService
    property var popupScreen: null
    property string sysfsBatteryPath: ""
    property bool sysfsBatteryPresent: false
    property int sysfsBatteryPercentValue: 0
    property string sysfsBatteryState: "Unknown"
    property real sysfsBatterySecondsRemainingValue: 0
    property real sysfsBatteryRateWattsValue: 0
    property real popupRightMargin: Theme.gap * 2
    property string openPopup: ""
    readonly property bool audioOpen: root.openPopup === "audio"
    readonly property bool networkOpen: root.openPopup === "network"
    readonly property bool batteryOpen: root.openPopup === "battery"
    readonly property int audioPercent: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100)
    readonly property bool audioMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    readonly property string networkIcon: iconForNetwork()
    readonly property var laptopBattery: laptopBatteryDevice()
    readonly property bool hasBattery: laptopBattery !== null || sysfsBatteryPresent
    readonly property int batteryPercent: Math.round(laptopBattery !== null ? laptopBattery.percentage * 100 : sysfsBatteryPercentValue)
    readonly property real audioPanelHeight: Math.min(560, Math.max(220, audioView.implicitHeight + Theme.panelPadding * 2))
    readonly property real networkPanelHeight: 510
    readonly property real batteryPanelHeight: batteryContent.implicitHeight + Theme.panelPadding * 2

    onNetworkOpenChanged: {
        if (root.networkOpen)
            root.networkService.requestScan(true);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    FileView {
        id: batteryPresentFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/present` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryCapacityFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/capacity` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryStatusFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/status` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryPowerNowFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/power_now` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryEnergyNowFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/energy_now` : ""
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: batteryEnergyFullFile

        path: root.sysfsBatteryPath.length > 0 ? `${root.sysfsBatteryPath}/energy_full` : ""
        blockAllReads: true
        printErrors: false
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.sysfsBatteryPath.length > 0 && root.laptopBattery === null
        triggeredOnStart: true
        onTriggered: root.updateSysfsBattery()
    }

    Process {
        id: batteryPathProcess

        stdout: StdioCollector {
            id: batteryPathOutput

            onStreamFinished: root.applySysfsBatteryPath(batteryPathOutput.text)
        }
    }

    Component.onCompleted: root.refreshSysfsBatteryPath()
    onSysfsBatteryPathChanged: root.updateSysfsBattery()

    function modelValues(model) {
        return model?.values ?? [];
    }

    function iconForNetwork() {
        if (root.networkService.networkState !== "connected")
            return "󰤭";

        if (root.networkService.networkType === "ethernet")
            return "󰈀";

        return "󰤨";
    }

    function laptopBatteryDevice() {
        return root.modelValues(UPower.devices).find(device => device.isLaptopBattery && device.isPresent) ?? null;
    }

    function refreshSysfsBatteryPath() {
        batteryPathProcess.exec(["sh", "-lc", 'for battery in /sys/class/power_supply/BAT*; do [ -d "$battery" ] || continue; read -r type < "$battery/type" || continue; read -r present < "$battery/present" || continue; [ "$type" = "Battery" ] && [ "$present" = "1" ] && printf "%s" "$battery" && break; done']);
    }

    function applySysfsBatteryPath(output) {
        root.sysfsBatteryPath = output.trim();
    }

    function readNumber(file) {
        const value = Number(file.text().trim());

        return Number.isFinite(value) ? value : 0;
    }

    function updateSysfsBattery() {
        if (root.sysfsBatteryPath.length === 0)
            return;

        batteryPresentFile.reload();
        batteryCapacityFile.reload();
        batteryStatusFile.reload();
        batteryPowerNowFile.reload();
        batteryEnergyNowFile.reload();
        batteryEnergyFullFile.reload();

        const present = batteryPresentFile.text().trim() === "1";
        const capacity = root.readNumber(batteryCapacityFile);
        const status = batteryStatusFile.text().trim();
        const powerWatts = root.readNumber(batteryPowerNowFile) / 1000000;
        const energyNow = root.readNumber(batteryEnergyNowFile) / 1000000;
        const energyFull = root.readNumber(batteryEnergyFullFile) / 1000000;

        root.sysfsBatteryPresent = present;
        root.sysfsBatteryPercentValue = Math.max(0, Math.min(100, Math.round(capacity)));
        root.sysfsBatteryState = status.length > 0 ? status : "Unknown";
        root.sysfsBatteryRateWattsValue = Math.max(0, powerWatts);

        if (!present || powerWatts <= 0) {
            root.sysfsBatterySecondsRemainingValue = 0;
            return;
        }

        if (status === "Charging" && energyFull > energyNow) {
            root.sysfsBatterySecondsRemainingValue = (energyFull - energyNow) / powerWatts * 3600;
            return;
        }

        if (status === "Discharging" && energyNow > 0) {
            root.sysfsBatterySecondsRemainingValue = energyNow / powerWatts * 3600;
            return;
        }

        root.sysfsBatterySecondsRemainingValue = 0;
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

        anchors.centerIn: parent
        width: statusContent.implicitWidth
        height: statusContent.implicitHeight

        Row {
            id: statusContent

            anchors.centerIn: parent
            spacing: Theme.gap * 5

            Item {
                id: audioSegment

                y: (statusContent.implicitHeight - height) / 2
                z: audioTrigger.containsMouse ? 1 : 0
                width: audioRow.implicitWidth
                height: 28

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 1.5
                        rightMargin: -Theme.gap * 1.5
                    }
                    color: audioTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                Row {
                    id: audioRow

                    anchors.centerIn: parent
                    spacing: Theme.gap * 2

                    Text {
                        text: root.audioMuted ? "󰖁" : ""
                        color: root.audioMuted ? Theme.muted : Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                    }

                    Text {
                        text: root.audioMuted ? "Muted" : root.formatPercent(root.audioPercent)
                        color: root.audioMuted ? Theme.muted : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                    }
                }

                MouseArea {
                    id: audioTrigger

                    anchors.fill: parent
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

                y: (statusContent.implicitHeight - height) / 2
                z: networkTrigger.containsMouse ? 1 : 0
                width: networkRow.implicitWidth
                height: 28

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 1.5
                        rightMargin: -Theme.gap * 1.5
                    }
                    color: networkTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
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

                    Text {
                        text: root.networkService.networkLabel
                        width: Math.min(92, implicitWidth)
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        font.bold: true
                    }
                }

                MouseArea {
                    id: networkTrigger

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePopup("network")
                }
            }

            Item {
                id: batterySegment

                y: (statusContent.implicitHeight - height) / 2
                z: batteryTrigger.containsMouse ? 1 : 0
                visible: root.hasBattery
                width: visible ? batteryRow.implicitWidth : 0
                height: 28

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 1.5
                        rightMargin: -Theme.gap * 2
                    }
                    color: batteryTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                Row {
                    id: batteryRow

                    anchors.centerIn: parent
                    spacing: Theme.gap * 2

                    Text {
                        text: "󰁹"
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                    }

                    Text {
                        text: root.formatPercent(root.batteryPercent)
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: true
                    }
                }

                MouseArea {
                    id: batteryTrigger

                    anchors.fill: parent
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
                dismissOnExit: true
                onDismissRequested: root.closePopup("audio")

                length: 340
                depth: root.audioPanelHeight
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    right: parent.right
                }

                Flickable {
                    id: audioContent

                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: audioView.implicitHeight
                    interactive: contentHeight > height

                    Media {
                        id: audioView

                        width: parent.width
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
        WlrLayershell.keyboardFocus: root.networkOpen && networkView.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                dismissOnExit: !networkView.editing && !root.networkService.actionPending
                onDismissRequested: root.closePopup("network")

                length: 360
                depth: root.networkPanelHeight
                duration: 150

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    right: parent.right
                }

                Flickable {
                    id: networkContent

                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: networkView.implicitHeight
                    interactive: contentHeight > height

                    Network {
                        id: networkView

                        width: parent.width
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
                dismissOnExit: true
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
                        fallbackPercent: root.sysfsBatteryPercentValue
                        fallbackState: root.sysfsBatteryState
                        fallbackSecondsRemaining: root.sysfsBatterySecondsRemainingValue
                        fallbackRateWatts: root.sysfsBatteryRateWattsValue
                    }
                }
            }
        }
    }
}
