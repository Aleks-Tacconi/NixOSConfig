import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: aiChatLoader.implicitWidth
            implicitHeight: aiChatLoader.implicitHeight
            radius: Appearance.rounding.normal
            color: "#181818"
            border.width: 1
            border.color: "#262626"

            AiChat {
                id: aiChatLoader
                anchors.fill: parent
            }
        }
    }
}
