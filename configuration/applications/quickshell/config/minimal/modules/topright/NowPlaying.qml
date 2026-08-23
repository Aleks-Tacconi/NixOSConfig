import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"

/**
 * Track metadata, seek controls, and playback actions for one MPRIS player.
 */
Item {
    id: root

    required property var player
    property int playerCount: 1
    property int selectedPlayerIndex: 0

    signal cyclePlayer

    readonly property real trackLengthSec: root.player?.lengthSupported ? root.player.length : 0
    readonly property real trackPositionSec: root.player?.position ?? 0

    implicitHeight: content.implicitHeight

    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    function formatTime(seconds) {
        const totalSeconds = Math.floor(seconds)
        const minutes = Math.floor(totalSeconds / 60)
        const remainingSeconds = totalSeconds % 60
        return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.gap * 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            Frame.PanelGroupLabel {
                Layout.fillWidth: true
                title: "Now playing"
                detail: root.playerCount > 1
                    ? `${root.player?.identity || "Media"} · ${Math.min(root.selectedPlayerIndex + 1, root.playerCount)}/${root.playerCount}`
                    : (root.player?.identity || "Media")
            }

            MediaControlButton {
                visible: root.playerCount > 1
                controlSize: 32
                icon: "󰑓"
                onClicked: root.cyclePlayer()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 3

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: Theme.surfaceRadius
                color: Theme.panelSurface
                clip: true

                Image {
                    id: artwork

                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: artwork.status !== Image.Ready
                    text: "󰝚"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "No track"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    font.bold: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || "Unknown artist"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            Text {
                text: root.formatTime(root.trackPositionSec)
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Theme.bg2

                Rectangle {
                    width: parent.width * (root.trackLengthSec > 0 ? Math.min(root.trackPositionSec / root.trackLengthSec, 1) : 0)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.red
                }

                Rectangle {
                    visible: (root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false) && (root.player?.lengthSupported ?? false) && root.trackLengthSec > 0
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.trackPositionSec / root.trackLengthSec - width / 2))
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.fg
                }

                MouseArea {
                    anchors {
                        fill: parent
                        topMargin: -8
                        bottomMargin: -8
                    }
                    enabled: root.player?.canSeek ?? false
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        if (root.player.positionSupported && root.player.lengthSupported && root.trackLengthSec > 0)
                            root.player.position = mouse.x / width * root.trackLengthSec
                    }
                    onPositionChanged: mouse => {
                        if (pressed && root.player.positionSupported && root.player.lengthSupported && root.trackLengthSec > 0)
                            root.player.position = Math.max(0, Math.min(root.trackLengthSec, mouse.x / width * root.trackLengthSec))
                    }
                    onWheel: wheel => root.player.seek(wheel.angleDelta.y > 0 ? 5 : -5)
                }
            }

            Text {
                text: root.formatTime(root.trackLengthSec)
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            Item {
                Layout.fillWidth: true
            }

            MediaControlButton {
                icon: "󰒮"
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            MediaControlButton {
                icon: root.player?.isPlaying ? "󰏤" : "󰐊"
                primary: true
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }

            MediaControlButton {
                icon: "󰒭"
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
