import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Typographic popup title or subsection label with optional detail.
 */
Item {
    id: root

    required property string title

    property string detail: ""
    property color titleColor: root.primary ? Theme.fg : Theme.muted
    property color detailColor: Theme.muted
    property bool detailStrong: false
    property bool primary: false
    property real topPadding: root.primary ? Theme.gap / 2 : Theme.gap * 3
    property real bottomPadding: root.primary ? Theme.gap / 2 : Theme.gap

    implicitWidth: headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight + root.topPadding + root.bottomPadding

    RowLayout {
        id: headerRow

        anchors {
            fill: parent
            topMargin: root.topPadding
            bottomMargin: root.bottomPadding
        }
        spacing: Theme.gap * 2

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.title
            color: root.titleColor
            font.family: Theme.fontFamily
            font.pixelSize: root.primary ? Theme.panelTitleSize : Theme.panelCaptionSize
            font.bold: true
            font.capitalization: root.primary ? Font.MixedCase : Font.AllUppercase
            font.letterSpacing: root.primary ? 0 : 0.6
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
