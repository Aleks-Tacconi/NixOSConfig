import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../frame" as Frame
import "../../theme"

/**
 * Battery status card using UPower when available, with sysfs fallback.
 */
Item {
    id: root

    implicitHeight: content.implicitHeight
    property var device: null
    property int fallbackPercent: 0
    property string fallbackState: "Unknown"
    property real fallbackSecondsRemaining: 0
    property real fallbackRateWatts: 0
    readonly property bool usingFallback: root.device === null
    readonly property int percent: Math.round(root.usingFallback ? root.fallbackPercent : (device?.percentage ?? 0) * 100)
    readonly property real secondsRemaining: root.usingFallback ? root.fallbackSecondsRemaining : upowerSecondsRemaining()
    readonly property var availableProfiles: [{
        label: "Saver",
        icon: "󰌪",
        profile: PowerProfile.PowerSaver
    }, {
        label: "Balanced",
        icon: "󰾅",
        profile: PowerProfile.Balanced
    }].concat(PowerProfiles.hasPerformanceProfile ? [{
        label: "Performance",
        icon: "󰓅",
        profile: PowerProfile.Performance
    }] : [])

    function upowerSecondsRemaining() {
        const timeToEmpty = device?.timeToEmpty ?? 0
        const timeToFull = device?.timeToFull ?? 0

        return timeToEmpty > 0 ? timeToEmpty : timeToFull
    }

    function stateText() {
        if (root.usingFallback)
            return root.fallbackState.length > 0 ? root.fallbackState : "Unavailable"

        if (!root.device)
            return "Unavailable"

        return UPowerDeviceState.toString(root.device.state)
    }

    function remainingText() {
        if (["Full", "Fully Charged"].includes(root.stateText()))
            return "fully charged"

        if (root.secondsRemaining <= 0)
            return "time unknown"

        const hours = Math.floor(root.secondsRemaining / 3600)
        const minutes = Math.round((root.secondsRemaining % 3600) / 60)

        if (hours <= 0)
            return `${minutes}m remaining`

        return `${hours}h ${minutes}m remaining`
    }

    function rateText() {
        if (root.usingFallback) {
            const rate = root.fallbackRateWatts

            if (rate < 0.1)
                return ["Full", "Fully Charged"].includes(root.stateText()) ? "charged" : "idle"

            return `${rate.toFixed(1)} W ${root.stateText() === "Charging" ? "in" : "out"}`
        }

        const rate = root.device?.changeRate ?? 0

        if (Math.abs(rate) < 0.1)
            return "idle"

        return `${Math.abs(rate).toFixed(1)} W ${rate > 0 ? "in" : "out"}`
    }

    function degradationText() {
        return PowerProfiles.degradationReason === 0 ? "" : "Performance limited"
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Battery"
            detail: `${root.percent}%`
            detailColor: Theme.red
            detailStrong: true
            primary: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 3

            Text {
                text: "󰁹"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Theme.bg2

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: Theme.red
                }
            }
        }

        Item {
            Layout.preferredHeight: Theme.panelSectionGap - Theme.panelItemGap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.panelItemGap
            rowSpacing: Theme.gap

            Text {
                text: "Status"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: root.stateText()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }

            Text {
                text: "Remaining"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: root.remainingText()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }

            Text {
                text: "Rate"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: root.rateText()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }

            Text {
                visible: !root.usingFallback && (root.device?.healthSupported ?? false)
                text: "Health"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                visible: !root.usingFallback && (root.device?.healthSupported ?? false)
                Layout.fillWidth: true
                text: `${Math.round(root.device?.healthPercentage ?? 0)}% · ${(root.device?.energy ?? 0).toFixed(1)} / ${(root.device?.energyCapacity ?? 0).toFixed(1)} Wh`
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            Layout.preferredHeight: Theme.panelSectionGap - Theme.panelItemGap
        }

        Frame.PanelGroupLabel {
            Layout.fillWidth: true
            title: "Power mode"
            detail: root.degradationText()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            Repeater {
                model: root.availableProfiles

                PowerProfileButton {
                    required property var modelData

                    Layout.fillWidth: true
                    label: modelData.label
                    icon: modelData.icon
                    active: PowerProfiles.profile === modelData.profile
                    onClicked: PowerProfiles.profile = modelData.profile
                }
            }
        }

    }
}
