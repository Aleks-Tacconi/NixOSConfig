pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Monospaced time display for the bar. */
Text {
    id: clock

    color: Theme.red
    font.family: Theme.monoFontFamily
    font.pixelSize: Theme.fontSize

    anchors {
        verticalCenter: parent.verticalCenter
    }

    text: Qt.formatDateTime(new Date(), "hh:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            clock.text = Qt.formatDateTime(new Date(), "hh:mm");
        }
    }
}
