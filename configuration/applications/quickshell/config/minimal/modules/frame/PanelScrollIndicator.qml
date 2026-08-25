import QtQuick
import "../../theme"

/**
 * Persistent vertical scroll indicator for clipped popup content.
 */
Item {
    id: root

    required property Flickable flickable

    readonly property real heightRatio: Math.min(1, root.flickable.visibleArea.heightRatio)
    readonly property real scrollProgress: root.heightRatio < 1
        ? Math.max(0, Math.min(1, root.flickable.visibleArea.yPosition / (1 - root.heightRatio)))
        : 0

    visible: root.flickable.contentHeight > root.flickable.height + 1
    width: 3

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: parent.height
        radius: 1
        color: Theme.fg
        opacity: 0.12
    }

    Rectangle {
        width: parent.width
        height: Math.max(28, parent.height * root.heightRatio)
        y: (parent.height - height) * root.scrollProgress
        radius: width / 2
        color: Theme.fg
        opacity: root.flickable.movingVertically ? 0.72 : 0.42

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }
}
