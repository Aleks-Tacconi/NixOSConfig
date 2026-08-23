pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/**
 * Bottom search input for the launcher.
 */
Rectangle {
    id: root

    required property bool open
    required property string placeholder
    property alias text: searchInput.text
    readonly property bool hasSelection: searchInput.selectedText.length > 0

    signal keyPressed(var event)

    function forceInputFocus() {
        searchInput.forceActiveFocus();
    }

    width: parent?.width ?? 0
    height: 44
    radius: Theme.surfaceRadius
    color: searchInput.activeFocus ? Theme.panelSurfaceHover : Theme.panelSurface
    border.width: searchInput.activeFocus ? 1 : 0
    border.color: Theme.popupInnerEdge

    Text {
        anchors {
            left: parent.left
            leftMargin: Theme.panelPadding
            verticalCenter: parent.verticalCenter
        }

        color: Theme.red
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelBodySize
        text: ""
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 48
            right: clearButton.left
            rightMargin: Theme.gap
            verticalCenter: parent.verticalCenter
        }

        visible: searchInput.text.length === 0
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        text: root.placeholder
    }

    TextInput {
        id: searchInput

        anchors {
            fill: parent
            leftMargin: 48
            rightMargin: searchInput.text.length > 0 ? 44 : Theme.gap * 3
        }

        color: Theme.fg
        selectionColor: Theme.red
        selectedTextColor: "#000000"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelBodySize
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        focus: root.open

        Keys.onPressed: event => root.keyPressed(event)
    }

    Rectangle {
        id: clearButton

        visible: searchInput.text.length > 0
        anchors {
            right: parent.right
            rightMargin: Theme.gap
            verticalCenter: parent.verticalCenter
        }
        width: 34
        height: 34
        radius: Theme.surfaceRadius
        color: clearMouse.containsMouse ? Theme.panelSurface : "transparent"

        Text {
            anchors.centerIn: parent
            text: "×"
            color: clearMouse.containsMouse ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
        }

        MouseArea {
            id: clearMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }
    }
}
