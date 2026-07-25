import QtQuick
import "../../theme"

Rectangle {
    id: root

    required property string time
    required property string title

    width: parent?.width ?? 0
    height: Theme.panelRowHeight
    radius: Theme.surfaceRadius
    color: Theme.panelSurface
    border.width: 0

    Row {
        anchors {
            fill: parent
            leftMargin: Theme.gap * 2
            rightMargin: Theme.gap * 2
        }

        spacing: Theme.gap * 2

        Text {
            width: 90
            anchors.verticalCenter: parent.verticalCenter
            text: root.time
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            width: parent.width - 100
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            maximumLineCount: 1
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
