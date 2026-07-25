pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../frame" as Frame
import "../../theme"

/**
 * App action sheet and window previews for the dock pullout.
 */
Column {
    id: root

    required property var appGroup
    required property var dataSource

    readonly property string appId: root.appGroup?.appId ?? ""
    readonly property int windowCount: root.appGroup?.toplevels?.length ?? 0
    readonly property bool pinned: root.dataSource.isPinned(root.appId)
    readonly property string iconSource: root.dataSource.iconSourceForApp(root.appId)

    signal windowCloseRequested(var toplevel)

    spacing: Theme.panelSectionGap

    ColumnLayout {
        width: parent.width
        height: implicitHeight
        spacing: Theme.panelItemGap

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap * 2

            IconImage {
                visible: root.iconSource.length > 0
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                source: root.iconSource
            }

            Rectangle {
                visible: root.iconSource.length === 0
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: Theme.surfaceRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    font.bold: true
                    text: root.appId[0]?.toUpperCase() ?? "?"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    font.bold: true
                    text: root.appId.length > 0 ? root.appId : "Unknown App"
                }

                Text {
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    text: root.windowCount === 1 ? "1 window" : `${root.windowCount} windows`
                }
            }

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: Theme.surfaceRadius
                color: pinMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    color: root.pinned ? Theme.red : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                    text: root.pinned ? "󰐃" : "󰐂"
                }

                MouseArea {
                    id: pinMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.dataSource.togglePinned(root.appId)
                }
            }
        }
    }

    Text {
        visible: root.windowCount > 0
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        text: "Windows"
    }

    Column {
        id: windowsColumn

        visible: root.windowCount > 0
        width: parent.width
        spacing: Theme.panelItemGap

        Repeater {
            model: root.appGroup?.toplevels ?? []

            delegate: DockWindowRow {
                required property var modelData

                width: windowsColumn.width
                dataSource: root.dataSource
                toplevel: modelData
                onCloseRequested: toplevel => root.windowCloseRequested(toplevel)
            }
        }
    }
}
