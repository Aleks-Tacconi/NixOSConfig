import QtQuick
import "../../theme"

Text {
    id: clock

    color: Theme.red
    font.family: Theme.fontFamily
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
