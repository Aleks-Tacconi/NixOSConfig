pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** A keyboard-accessible wallpaper thumbnail with a quiet selection marker. */
Item {
    id: root
    required property url imageSource
    required property string label
    property bool selected: false
    signal clicked

    activeFocusOnTab: root.enabled
    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors {
            fill: parent
            margins: Theme.gap
        }
        radius: Theme.cardRadius
        color: tileMouse.containsMouse || root.activeFocus ? Theme.panelSurfaceHover : Theme.panelSurface
        border.width: root.selected ? Theme.popupBorderWidth : 0
        border.color: Theme.focusBorder
        clip: true
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Image {
            id: thumbnail
            anchors {
                fill: parent
                margins: Theme.gap
                bottomMargin: Theme.panelRowHeight
            }
            source: root.imageSource
            sourceSize.width: 400
            sourceSize.height: 300
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            scale: tileMouse.containsMouse ? 1.035 : 1
            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Theme.gap * 2
            }
            text: root.selected ? `✓ ${root.label}` : root.label
            color: root.selected ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            elide: Text.ElideRight
        }

        Text {
            anchors.centerIn: thumbnail
            visible: thumbnail.status === Image.Error
            text: "Preview unavailable"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
