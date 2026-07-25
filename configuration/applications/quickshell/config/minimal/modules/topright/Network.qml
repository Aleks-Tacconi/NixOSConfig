import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"

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
    readonly property bool connected: state === "connected"
    readonly property bool wired: type === "ethernet"

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
            spacing: Theme.gap * 3

            Text {
                text: root.iconText()
                color: root.connected ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
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

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 4

            Text {
                text: `↓ ${root.down}`
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                text: `↑ ${root.up}`
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Frame.PanelDivider {
            Layout.fillWidth: true
        }
    }
}
