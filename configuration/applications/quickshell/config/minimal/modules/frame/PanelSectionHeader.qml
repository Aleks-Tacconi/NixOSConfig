import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Primary popup title with optional trailing detail.
 */
Item {
    id: root

    required property string title

    property string detail: ""
    property color detailColor: Theme.muted
    property bool detailStrong: false
    property real verticalPadding: Theme.gap / 2

    implicitWidth: headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight + root.verticalPadding * 2

    RowLayout {
        id: headerRow

        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: Theme.gap * 2

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.title
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: root.detail.length > 0
            Layout.maximumWidth: root.width * 0.5
            text: root.detail
            color: root.detailColor
            font.family: Theme.fontFamily
            font.pixelSize: root.detailStrong ? Theme.panelBodySize : Theme.panelCaptionSize
            font.bold: root.detailStrong
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
