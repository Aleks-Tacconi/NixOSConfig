import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Shared action row used across popup menus and lists.
 */
Rectangle {
    id: root

    required property string label

    property string icon: ""
    property bool active: false
    property color accentColor: Theme.red
    property string detailText: ""
    property string trailingText: "›"
    property bool showTrailing: false
    property real horizontalPadding: Theme.gap * 2

    readonly property bool hovered: mouseArea.containsMouse

    signal clicked

    implicitHeight: Theme.panelRowHeight
    height: implicitHeight
    radius: Theme.surfaceRadius
    color: root.hovered && root.enabled ? Theme.panelSurfaceHover : (root.active && root.enabled ? Theme.panelSurface : "transparent")
    opacity: root.enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        spacing: Theme.gap * 2

        Text {
            Layout.preferredWidth: Theme.fontSize + 10
            visible: root.icon.length > 0
            horizontalAlignment: Text.AlignHCenter
            color: !root.enabled ? Theme.muted : (root.active || root.hovered ? root.accentColor : Theme.muted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            text: root.icon
        }

        Text {
            Layout.fillWidth: true
            color: !root.enabled ? Theme.muted : (root.active || root.hovered ? Theme.fg : Theme.muted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            elide: Text.ElideRight
            text: root.label
        }

        Text {
            visible: root.detailText.length > 0
            color: root.active && root.enabled ? root.accentColor : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            horizontalAlignment: Text.AlignRight
            text: root.detailText
        }

        Text {
            visible: root.showTrailing
            color: root.hovered && root.enabled ? root.accentColor : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
            opacity: root.enabled ? 1 : 0.45
            text: root.trailingText
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
