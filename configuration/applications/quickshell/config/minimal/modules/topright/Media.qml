import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../frame" as Frame
import "../../theme"

/**
 * Pipewire output volume, device controls, and single selectable MPRIS media player.
 */
Item {
    id: root

    implicitHeight: content.implicitHeight

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var outputDevices: Pipewire.nodes.values.filter(node => node.audio !== null && node.isSink && !node.isStream)
    readonly property int volume: Math.round((defaultSink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: defaultSink?.audio?.muted ?? false

    property int selectedPlayerIndex: 0
    readonly property var players: Mpris.players.values
    readonly property int playerCount: players.length
    readonly property var selectedPlayer: playerCount > 0
        ? players[Math.min(selectedPlayerIndex, playerCount - 1)]
        : null

    onPlayerCountChanged: {
        if (selectedPlayerIndex >= playerCount)
            selectedPlayerIndex = Math.max(0, playerCount - 1)
    }

    PwObjectTracker {
        objects: [root.defaultSink].concat(root.outputDevices)
    }

    function deviceName(node) {
        if (!node)
            return "No output device"

        if (node.description.length > 0)
            return node.description
        if (node.nickname.length > 0)
            return node.nickname

        return node.name
    }

    function setVolumePercent(percent) {
        const audio = root.defaultSink?.audio

        if (!audio)
            return

        audio.volume = Math.max(0, Math.min(1.5, percent / 100))
    }

    function adjustVolume(delta) {
        root.setVolumePercent(root.volume + delta)
    }

    function toggleMute() {
        const audio = root.defaultSink?.audio

        if (audio)
            audio.muted = !audio.muted
    }

    function cyclePlayer() {
        if (root.playerCount <= 1)
            return

        root.selectedPlayerIndex = (root.selectedPlayerIndex + 1) % root.playerCount
    }

    function formatTime(sec) {
        const totalSeconds = Math.floor(sec)
        const minutes = Math.floor(totalSeconds / 60)
        const seconds = totalSeconds % 60
        return `${minutes}:${seconds.toString().padStart(2, "0")}`
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        Item {
            id: mediaItem

            Layout.fillWidth: true
            implicitHeight: playerLayout.implicitHeight + Theme.gap * 4
            visible: root.selectedPlayer !== null

            readonly property var player: root.selectedPlayer
            readonly property real trackLengthSec: player?.length ?? 0
            readonly property real trackPositionSec: player?.position ?? 0

            Timer {
                interval: 1000
                repeat: true
                running: mediaItem.player?.isPlaying ?? false
                onTriggered: mediaItem.player.positionChanged()
            }

            ColumnLayout {
                id: playerLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.gap * 2
                }

                spacing: Theme.gap * 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap * 2

                    Text {
                        text: mediaItem.player?.identity || "Media"
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelTitleSize
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.playerCount > 1
                        text: `${Math.min(root.selectedPlayerIndex + 1, root.playerCount)}/${root.playerCount}`
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                    }

                    Text {
                        visible: root.playerCount > 1
                        text: "󰑓"
                        color: Theme.red
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.cyclePlayer()
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap

                    Text {
                        Layout.fillWidth: true
                        text: mediaItem.player?.trackTitle || "No track"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelBodySize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: mediaItem.player?.trackArtist || "Unknown artist"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap * 2

                    Text {
                        text: root.formatTime(mediaItem.trackPositionSec)
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Theme.bg2

                        Rectangle {
                            width: parent.width * (mediaItem.trackLengthSec > 0
                                ? Math.min(mediaItem.trackPositionSec / mediaItem.trackLengthSec, 1)
                                : 0)
                            height: parent.height
                            radius: parent.radius
                            color: Theme.red
                        }
                    }

                    Text {
                        text: root.formatTime(mediaItem.trackLengthSec)
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

                    Text {
                        text: "󰒮"
                        color: mediaItem.player?.canGoPrevious ? Theme.fg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2

                        MouseArea {
                            anchors.fill: parent
                            enabled: mediaItem.player?.canGoPrevious ?? false
                            onClicked: mediaItem.player.previous()
                        }
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.radius * 2
                        color: Theme.bg2

                        Text {
                            anchors.centerIn: parent
                            text: mediaItem.player?.isPlaying ? "󰏤" : "󰐊"
                            color: mediaItem.player?.canTogglePlaying ? Theme.red : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: mediaItem.player?.canTogglePlaying ?? false
                            onClicked: mediaItem.player.togglePlaying()
                        }
                    }

                    Text {
                        text: "󰒭"
                        color: mediaItem.player?.canGoNext ? Theme.fg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2

                        MouseArea {
                            anchors.fill: parent
                            enabled: mediaItem.player?.canGoNext ?? false
                            onClicked: mediaItem.player.next()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Frame.PanelDivider {
            Layout.fillWidth: true
            visible: root.playerCount > 0
        }

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Audio"
            detail: root.muted ? "Muted" : `${root.volume}%`
            detailColor: root.muted ? Theme.muted : Theme.fg
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 3

            Text {
                text: root.muted ? "󰖁" : ""
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Theme.bg2

                Rectangle {
                    width: parent.width * Math.min(root.volume, 100) / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.muted ? Theme.muted : Theme.red
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: mouse => root.setVolumePercent(mouse.x / width * 100)
                    onPositionChanged: mouse => {
                        if (pressed)
                            root.setVolumePercent(mouse.x / width * 100)
                    }
                    onWheel: wheel => root.adjustVolume(wheel.angleDelta.y > 0 ? 5 : -5)
                }
            }

            Text {
                text: "−"
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.adjustVolume(-5)
                }
            }

            Text {
                text: "+"
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.adjustVolume(5)
                }
            }

            Text {
                text: root.muted ? "Unmute" : "Mute"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMute()
                }
            }
        }

        Frame.PanelDivider {
            Layout.fillWidth: true
        }

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Output"
            titleColor: Theme.redTwo
        }

        Column {
            id: deviceList

            Layout.fillWidth: true
            spacing: Theme.gap

            Repeater {
                model: root.outputDevices

                Rectangle {
                    required property var modelData

                    width: deviceList.width
                    height: Theme.panelRowHeight
                    radius: Theme.surfaceRadius
                    color: modelData === root.defaultSink ? Theme.panelSurfaceHover : (deviceMouse.containsMouse ? Theme.panelSurface : "transparent")
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.gap * 2
                        anchors.rightMargin: Theme.gap * 2
                        spacing: Theme.gap * 2

                        Text {
                            text: modelData === root.defaultSink ? "●" : "○"
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.deviceName(modelData)
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                        }
                    }

                    MouseArea {
                        id: deviceMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }

            Text {
                visible: root.outputDevices.length === 0
                text: "No output devices"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }
        }
    }
}
