import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Compact inline label for a content group, with optional trailing context.
 */
Item {
    id: root

    required property string title
    property string detail: ""

    implicitWidth: labelRow.implicitWidth
    implicitHeight: labelRow.implicitHeight + Theme.gap

    RowLayout {
        id: labelRow

        anchors {
            fill: parent
            topMargin: Theme.gap / 2
            bottomMargin: Theme.gap / 2
        }
        spacing: Theme.gap * 2

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.title
            color: Theme.muted
            opacity: 0.72
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: root.detail.length > 0
            Layout.maximumWidth: root.width * 0.5
            text: root.detail
            color: Theme.muted
            opacity: 0.58
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
