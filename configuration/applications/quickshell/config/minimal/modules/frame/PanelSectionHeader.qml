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
    property bool showMarker: true

    implicitWidth: headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight
    width: parent?.width ?? implicitWidth

    RowLayout {
        id: headerRow

        anchors.fill: parent
        spacing: Theme.gap * 2

        Rectangle {
            visible: root.showMarker
            Layout.preferredWidth: 3
            Layout.preferredHeight: Theme.panelTitleSize
            radius: 2
            color: root.titleColor
            opacity: 0.78
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.title
            color: root.titleColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: root.detail.length > 0
            Layout.maximumWidth: root.width * 0.45
            text: root.detail
            color: root.detailColor
            font.family: Theme.fontFamily
            font.pixelSize: root.detailStrong ? Theme.panelBodySize : Theme.panelMetaSize
            font.bold: root.detailStrong
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
