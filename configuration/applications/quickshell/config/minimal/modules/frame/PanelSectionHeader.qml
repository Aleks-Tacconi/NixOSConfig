import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Shared popup section header with optional trailing detail text.
 */
Item {
    id: root

    required property string title

    property string detail: ""
    property color titleColor: Theme.red
    property color detailColor: Theme.muted
    property bool detailStrong: false

    implicitWidth: headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight
    width: parent?.width ?? implicitWidth

    RowLayout {
        id: headerRow

        anchors.fill: parent
        spacing: Theme.gap * 2

        Text {
            text: root.title
            color: root.titleColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            font.bold: true
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            visible: root.detail.length > 0
            text: root.detail
            color: root.detailColor
            font.family: Theme.fontFamily
            font.pixelSize: root.detailStrong ? Theme.panelBodySize : Theme.panelMetaSize
            font.bold: root.detailStrong
            horizontalAlignment: Text.AlignRight
        }
    }
}
