import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"
import "../.." as ShellConfig

/**
 * Network connection and live transfer-rate readout.
 */
Item {
    id: root

    implicitHeight: content.implicitHeight

    property string interfaceName: ""
    property string label: "No network"
    property string state: "unavailable"
    property string type: "none"
    property string down: "0 KB/s"
    property string up: "0 KB/s"
    property bool tailscaleConnected: false
    property bool tailscalePending: false
    readonly property bool connected: state === "connected"
    readonly property bool wired: type === "ethernet"

    signal tailscaleToggleRequested

    function stateText() {
        if (root.state === "connected")
            return "Connected"
        if (root.state === "unavailable")
            return "Unavailable"

        return "Disconnected"
    }

    function iconText() {
        if (!root.connected)
            return "󰤭"

        return root.wired ? "󰈀" : "󰤨"
    }

    function detailText() {
        if (root.interfaceName.length === 0)
            return "No active interface"

        return `${root.interfaceName} · ${root.type}`
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Network"
            detail: root.stateText()
            detailColor: root.connected ? Theme.fg : Theme.muted
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            Text {
                Layout.preferredWidth: Theme.fontSize + 10
                text: root.iconText()
                color: root.connected ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                }

                Text {
                    Layout.fillWidth: true
                    text: root.detailText()
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.fontSize + 10 + Theme.gap * 2
            columns: 2
            columnSpacing: Theme.panelItemGap
            rowSpacing: Theme.gap

            Text {
                text: "↓ Download"
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: root.down
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }

            Text {
                text: "↑ Upload"
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: root.up
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
            }
        }

        Frame.PanelDivider {
            Layout.fillWidth: true
        }

        Frame.PanelActionRow {
            visible: ShellConfig.Config.network.tailscale
            Layout.fillWidth: true
            label: "Tailscale"
            icon: "󰒍"
            active: root.tailscaleConnected
            enabled: !root.tailscalePending
            detailText: root.tailscalePending ? "Working" : (root.tailscaleConnected ? "On" : "Off")
            onClicked: root.tailscaleToggleRequested()
        }
    }
}
