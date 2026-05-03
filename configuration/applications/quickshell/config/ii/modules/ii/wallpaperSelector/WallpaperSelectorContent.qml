import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

MouseArea {
    id: root

    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    property string titleFont: "Fira Sans Semibold"

    property color barBg: "#101010"
    property color shellBg: "#080808"
    property color moduleBg: "#181818"
    property color moduleBgActive: "#262626"
    property color textPrimary: "#f5f5f5"
    property color textMuted: "#8f8f8f"
    property color accent: "#ffffff"

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            Wallpapers.apply(filePath)
        }
    }

    Component.onCompleted: {
        Wallpapers.loadWallpapers()
    }

    Rectangle {
        id: container

        anchors.fill: parent

        implicitWidth: 900
        implicitHeight: 560

        color: root.barBg
        radius: 3
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 3
                    color: root.shellBg

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: "Wallpapers"
                            color: root.textPrimary

                            font {
                                family: root.titleFont
                                pixelSize: 16
                                weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            implicitWidth: wallpaperCount.implicitWidth + 16
                            implicitHeight: 24
                            radius: 3
                            color: root.moduleBg

                            Text {
                                id: wallpaperCount
                                anchors.centerIn: parent
                                text: Wallpapers.getWallpapersModel().count
                                color: root.textMuted

                                font {
                                    family: root.titleFont
                                    pixelSize: 13
                                    weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 105
                    implicitHeight: 42
                    radius: 3
                    color: randomMouse.containsMouse ? root.moduleBgActive : root.shellBg

                    Text {
                        anchors.centerIn: parent
                        text: "Random"
                        color: root.textPrimary
                        font.family: root.titleFont
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: randomMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Wallpapers.randomFromCurrentFolder()
                    }
                }

                Rectangle {
                    implicitWidth: 105
                    implicitHeight: 42
                    radius: 3
                    color: reloadMouse.containsMouse ? root.moduleBgActive : root.shellBg

                    Text {
                        anchors.centerIn: parent
                        text: "Reload"
                        color: root.textPrimary
                        font.family: root.titleFont
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: reloadMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Wallpapers.loadWallpapers()
                    }
                }

                Rectangle {
                    implicitWidth: 105
                    implicitHeight: 42
                    radius: 3
                    color: closeMouse.containsMouse ? root.moduleBgActive : root.shellBg

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: root.textPrimary
                        font.family: root.titleFont
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: GlobalStates.wallpaperSelectorOpen = false
                    }
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 2

                model: Wallpapers.getWallpapersModel()

                cellWidth: width / root.columns
                cellHeight: cellWidth / root.previewCellAspectRatio

                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: MouseArea {
                    id: itemRoot

                    required property string fileName
                    required property string filePath
                    required property string fileUrl
                    required property string originalFileUrl
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight
                    hoverEnabled: true

                    onClicked: root.selectWallpaperPath(filePath)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6

                        color: itemRoot.containsMouse ? root.moduleBgActive : root.moduleBg
                        radius: 3
                        border.width: 0

                        Rectangle {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                bottom: nameText.top
                                margins: 8
                            }

                            radius: 3
                            color: root.barBg
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: originalFileUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                        }

                        Text {
                            id: nameText

                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 8
                            }

                            height: 22

                            text: fileName
                            color: root.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight

                            font {
                                family: root.titleFont
                                pixelSize: 14
                                weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: 8
                                rightMargin: 8
                                bottomMargin: 6
                            }
                            height: 2
                            radius: 1
                            color: root.accent
                            visible: filePath === Config.options.background.wallpaperPath
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    Connections {
        target: Wallpapers

        function onFilesLoaded() {
            grid.forceLayout()
        }
    }

    Connections {
        target: Wallpapers

        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false
        }
    }
}
