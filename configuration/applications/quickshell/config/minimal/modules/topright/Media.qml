import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../frame" as Frame
import "../../theme"

/**
 * Pipewire volume and output controls followed by optional MPRIS playback.
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
        if (audio)
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
        if (root.playerCount > 1)
            root.selectedPlayerIndex = (root.selectedPlayerIndex + 1) % root.playerCount
    }

    ColumnLayout {
        id: content

        width: parent.width
        spacing: Theme.panelItemGap

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Audio"
        }

        Frame.PanelGroupLabel {
            Layout.fillWidth: true
            title: "Volume"
            detail: root.muted ? "Muted" : `${root.volume}%`
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
                Layout.preferredHeight: 4
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

            MediaControlButton {
                controlSize: 32
                icon: "−"
                onClicked: root.adjustVolume(-5)
            }

            MediaControlButton {
                controlSize: 32
                icon: "+"
                onClicked: root.adjustVolume(5)
            }

            MediaControlButton {
                controlSize: 32
                icon: root.muted ? "󰝟" : "󰝞"
                primary: root.muted
                onClicked: root.toggleMute()
            }
        }

        Item {
            Layout.preferredHeight: Theme.panelSectionGap - Theme.panelItemGap
        }

        Frame.PanelGroupLabel {
            Layout.fillWidth: true
            title: "Output device"
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(104, Math.max(Theme.panelRowHeight, deviceList.implicitHeight))

            Flickable {
                id: deviceScroll

                anchors {
                    fill: parent
                    rightMargin: Theme.gap * 2
                }
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: deviceList.implicitHeight
                interactive: contentHeight > height

                Column {
                    id: deviceList

                    width: deviceScroll.width
                    spacing: Theme.gap

                    Repeater {
                        model: root.outputDevices

                        Rectangle {
                            required property var modelData

                            width: deviceList.width
                            height: Theme.panelRowHeight
                            radius: Theme.surfaceRadius
                            color: modelData === root.defaultSink ? Theme.panelSurfaceHover : (deviceMouse.containsMouse ? Theme.panelSurface : "transparent")

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: Theme.gap * 2
                                    rightMargin: Theme.gap * 2
                                }
                                spacing: Theme.gap * 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.deviceName(modelData)
                                    elide: Text.ElideRight
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelMetaSize
                                }

                                Text {
                                    visible: modelData === root.defaultSink
                                    text: "Current"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelCaptionSize
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

            Frame.PanelScrollIndicator {
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 1
                }
                flickable: deviceScroll
            }
        }

        Item {
            visible: root.selectedPlayer !== null
            Layout.preferredHeight: visible ? Theme.panelSectionGap - Theme.panelItemGap : 0
        }

        NowPlaying {
            visible: root.selectedPlayer !== null
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            player: root.selectedPlayer
            playerCount: root.playerCount
            selectedPlayerIndex: root.selectedPlayerIndex
            onCyclePlayer: root.cyclePlayer()
        }
    }
}
