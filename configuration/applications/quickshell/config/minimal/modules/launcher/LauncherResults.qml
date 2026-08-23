pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/**
 * Scrollable launcher results list.
 */
Item {
    id: root

    required property var items
    required property int selectedIndex
    required property string emptyText

    property int rowHeight: 56

    signal activated(int index, var item)
    signal copyRequested(int index, var item)
    signal highlighted(int index)

    function resetViewport() {
        resultList.contentY = 0;
    }

    function ensureIndexVisible(index) {
        const rowTop = index * (root.rowHeight + resultsColumn.spacing);
        const rowBottom = rowTop + root.rowHeight;

        if (rowTop < resultList.contentY)
            resultList.contentY = rowTop;
        else if (rowBottom > resultList.contentY + resultList.height)
            resultList.contentY = rowBottom - resultList.height;
    }

    Flickable {
        id: resultList

        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: resultsColumn.implicitHeight
        interactive: contentHeight > height

        Column {
            id: resultsColumn

            width: resultList.width
            spacing: Theme.panelItemGap

            Repeater {
                model: root.items

                delegate: LauncherRow {
                    required property int index
                    required property var modelData

                    width: resultsColumn.width
                    height: root.rowHeight
                    item: modelData
                    selected: index === root.selectedIndex
                    onActivated: root.activated(index, modelData)
                    onCopyRequested: root.copyRequested(index, modelData)
                    onHoveredRequested: root.highlighted(index)
                }
            }

            Rectangle {
                visible: root.items.length === 0
                width: parent.width
                height: 156
                radius: Theme.cardRadius
                color: "transparent"
                border.width: 0

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.gap

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 8
                        text: ""
                    }

                    Text {
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        horizontalAlignment: Text.AlignHCenter
                        text: root.emptyText
                    }
                }
            }
        }
    }
}
