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

    signal keyPressed(var event)

    function forceInputFocus() {
        searchInput.forceActiveFocus();
    }

    width: parent?.width ?? 0
    height: 44
    radius: Theme.surfaceRadius
    color: searchInput.activeFocus ? Theme.panelSurfaceHover : "transparent"
    border.width: 0

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
            rightMargin: Theme.gap * 2
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
}
