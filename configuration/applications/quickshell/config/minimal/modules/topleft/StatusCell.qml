pragma ComponentBehavior: Bound

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
    property string labelFontFamily: Theme.fontFamily
    property color labelColor: Theme.fg
    property bool dotVisible: false
    property bool crossed: false
    property bool scrollLabel: false
    property bool scrollActive: false
    property int labelMaxWidth: 0

    readonly property bool labelOverflowing: labelMaxWidth > 0 && labelText.implicitWidth > labelMaxWidth

    width: content.implicitWidth
    height: 28

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
            clip: true

            Text {
                id: labelText

                x: 0
                width: root.scrollLabel && root.scrollActive ? implicitWidth : labelClip.width
                elide: Text.ElideRight
                text: root.label
                color: root.labelColor
                font.family: root.labelFontFamily
                font.pixelSize: Theme.fontSize + 1
                maximumLineCount: 1
                font.bold: true

                SequentialAnimation on x {
                    running: root.visible && root.scrollLabel && root.scrollActive && root.labelOverflowing
                    loops: Animation.Infinite
                    onStopped: labelText.x = 0

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
                visible: root.scrollLabel && root.scrollActive && root.labelOverflowing
                x: labelText.x + labelText.implicitWidth + Theme.gap * 8
                text: root.label
                color: root.labelColor
                font.family: root.labelFontFamily
                font.pixelSize: Theme.fontSize + 1
                maximumLineCount: 1
                font.bold: true
            }
        }
    }
}
