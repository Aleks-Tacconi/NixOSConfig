import QtQuick
import QtQuick.Layouts
import "../../theme"

/**
 * Minimal status cell for top bar indicators.
 */
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool dotVisible: false
    property bool crossed: false
    property bool scrollLabel: false
    property int labelMaxWidth: 0

    readonly property bool labelOverflowing: scrollLabel && labelMaxWidth > 0 && labelText.implicitWidth > labelMaxWidth

    width: content.implicitWidth
    height: 28

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Theme.radius
        border.width: 0
    }

    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: Theme.gap * 2

        Item {
            visible: root.icon.length > 0
            Layout.preferredWidth: iconText.implicitWidth
            Layout.preferredHeight: iconText.implicitHeight
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: iconText

                anchors.centerIn: parent
                text: root.icon
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
            }

            Rectangle {
                visible: root.dotVisible && !root.crossed
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: -3
                    topMargin: 1
                }

                width: 5
                height: 5
                radius: 2.5
                color: Theme.red
            }

            Rectangle {
                visible: root.crossed
                anchors.centerIn: parent
                width: parent.width + 6
                height: 2
                rotation: -35
                color: Theme.red
            }
        }

        Item {
            id: labelClip

            visible: root.label.length > 0
            Layout.preferredWidth: root.labelOverflowing ? root.labelMaxWidth : labelText.implicitWidth
            Layout.preferredHeight: labelText.implicitHeight
            Layout.alignment: Qt.AlignVCenter
            clip: root.labelOverflowing

            Text {
                id: labelText

                x: 0
                text: root.label
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                maximumLineCount: 1
                font.bold: true

                SequentialAnimation on x {
                    running: root.labelOverflowing
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 900
                    }

                    NumberAnimation {
                        to: -(labelText.implicitWidth + Theme.gap * 8)
                        duration: Math.max(4200, (labelText.implicitWidth + Theme.gap * 8) * 55)
                        easing.type: Easing.Linear
                    }

                    PropertyAction {
                        value: 0
                    }
                }
            }

            Text {
                visible: root.labelOverflowing
                x: labelText.x + labelText.implicitWidth + Theme.gap * 8
                text: root.label
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                maximumLineCount: 1
                font.bold: true
            }
        }
    }
}
