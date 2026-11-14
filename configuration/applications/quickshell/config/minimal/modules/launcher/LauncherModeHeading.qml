pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Show the current launcher mode as Tab cycles between enabled modes. */
Item {
    id: root

    required property string mode
    property string fileDir: ""
    property bool canGoBack: false
    property bool showNextHint: true
    readonly property string dirName: root.fileDir.split("/").filter(Boolean).pop() ?? ""
    readonly property string rightHint: [root.canGoBack ? "Backspace ←" : "", root.showNextHint ? "Tab → Next" : ""].filter(Boolean).join("  ·  ")
    readonly property var currentMode: ({
        applications: { label: "Applications", icon: "󰕮" },
        files: { label: "Files", icon: "󰈔" },
        emoji: { label: "Emoji", icon: "󰞅" },
        clipboard: { label: "Clipboard", icon: "" }
    })[root.mode]

    height: Theme.panelRowHeight

    Row {
        anchors {
            left: parent.left
            leftMargin: Theme.gap * 2
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.gap * 3

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentMode.icon
            color: Theme.muted
            font.family: Theme.iconFontFamily
            font.pixelSize: Theme.iconSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentMode.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            font.weight: Theme.emphasisWeight
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.dirName.length > 0
            text: `· ${root.dirName}`
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
        }
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: Theme.gap * 2
            verticalCenter: parent.verticalCenter
        }
        visible: root.rightHint.length > 0
        text: root.rightHint
        color: Theme.muted
        opacity: 0.7
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.panelCaptionSize
    }
}
