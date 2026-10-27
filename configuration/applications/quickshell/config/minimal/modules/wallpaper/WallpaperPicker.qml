pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import "../frame" as Frame
import "../../theme"
import "../.." as ShellConfig

/** Browse local wallpaper previews without leaving the notification panel. */
Item {
    id: root
    signal backRequested

    FolderListModel {
        id: wallpapers
        folder: ShellConfig.Config.wallpapers.directory
        showDirs: false
        showDotAndDotDot: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.jxl", "*.bmp"]
        caseSensitive: false
        sortField: FolderListModel.Name
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.panelItemGap

        Frame.PanelActionRow {
            Layout.fillWidth: true
            label: "Back to notifications"
            icon: "󰁍"
            onClicked: root.backRequested()
        }

        Frame.PanelSectionHeader {
            Layout.fillWidth: true
            title: "Wallpapers"
            detail: `${wallpapers.count} images`
        }

        Text {
            Layout.fillWidth: true
            text: WallpaperService.error || (WallpaperService.busy ? "Applying wallpaper…" : "Choose a new view. Applies to every screen.")
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid
                anchors.fill: parent
                anchors.rightMargin: Theme.gap * 2
                clip: true
                model: wallpapers
                cellWidth: grid.width / 2
                cellHeight: grid.cellWidth * 0.75 + Theme.panelRowHeight
                boundsBehavior: Flickable.StopAtBounds

                delegate: WallpaperTile {
                    required property url fileUrl
                    required property string fileBaseName
                    width: grid.cellWidth
                    height: grid.cellHeight
                    imageSource: fileUrl
                    label: fileBaseName
                    selected: WallpaperService.current === fileUrl.toString()
                    enabled: !WallpaperService.busy
                    onClicked: WallpaperService.apply(fileUrl.toString())
                }
            }

            Frame.PanelScrollIndicator {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                flickable: grid
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - Theme.panelPadding * 2
                visible: wallpapers.count === 0 && wallpapers.status !== FolderListModel.Loading
                text: "No wallpapers found.\nAdd images to your wallpapers directory."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
