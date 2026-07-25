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
    readonly property int percent: Math.round(root.usingFallback ? root.fallbackPercent : (device?.percentage ?? 0))
    readonly property real secondsRemaining: root.usingFallback ? root.fallbackSecondsRemaining : upowerSecondsRemaining()

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
        if (root.stateText() === "Full")
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
                return root.stateText() === "Full" ? "charged" : "idle"

            return `${rate.toFixed(1)} W ${root.stateText() === "Charging" ? "in" : "out"}`
        }

        const rate = root.device?.changeRate ?? 0

        if (Math.abs(rate) < 0.1)
            return "idle"

        return `${Math.abs(rate).toFixed(1)} W ${rate > 0 ? "in" : "out"}`
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

            Row {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: 20

                    Rectangle {
                        width: Math.max(4, (parent.width - 57) / 20)
                        height: 12
                        radius: 1
                        color: index < Math.round(root.percent / 5) ? Theme.red : Theme.bg2
                        border.width: 0
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 3

            Text {
                text: root.stateText()
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                text: root.remainingText()
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: root.rateText()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }
        }
    }
}
