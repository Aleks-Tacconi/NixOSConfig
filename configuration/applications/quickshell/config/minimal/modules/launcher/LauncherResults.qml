pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../frame" as Frame
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
        resultList.positionViewAtIndex(index, ListView.Contain);
    }

    ListView {
        id: resultList

        anchors {
            fill: parent
            rightMargin: Theme.gap * 2
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: Theme.panelItemGap
        model: ScriptModel { values: root.items }
        interactive: contentHeight > height

        delegate: LauncherRow {
            required property int index
            required property var modelData

            width: ListView.view.width
            height: root.rowHeight
            item: modelData
            selected: index === root.selectedIndex
            onActivated: root.activated(index, modelData)
            onCopyRequested: root.copyRequested(index, modelData)
            onHoveredRequested: root.highlighted(index)
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width
        visible: root.items.length === 0
        text: root.emptyText
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Frame.PanelScrollIndicator {
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            rightMargin: 1
        }
        flickable: resultList
    }
}
