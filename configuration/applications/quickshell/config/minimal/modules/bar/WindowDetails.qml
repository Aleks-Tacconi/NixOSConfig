pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Compact diagnostic rows for the focused window.
 */
ColumnLayout {
    id: root

    required property string windowTitle
    required property string pid
    required property string className
    required property string workspace

    spacing: Theme.gap

    Repeater {
        model: [{
            label: "Title",
            value: root.windowTitle,
            middleElide: false
        }, {
            label: "PID",
            value: root.pid,
            middleElide: false
        }, {
            label: "Class",
            value: root.className,
            middleElide: true
        }, {
            label: "Workspace",
            value: root.workspace,
            middleElide: false
        }]

        delegate: RowLayout {
            required property var modelData

            Layout.fillWidth: true
            spacing: Theme.panelItemGap

            Text {
                text: modelData.label
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }

            Text {
                Layout.fillWidth: true
                text: modelData.value
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                horizontalAlignment: Text.AlignRight
                elide: modelData.middleElide ? Text.ElideMiddle : Text.ElideRight
                textFormat: Text.PlainText
            }
        }
    }
}
