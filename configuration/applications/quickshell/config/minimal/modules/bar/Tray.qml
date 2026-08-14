pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "../frame" as Frame
import "../../theme"

/**
 * Collapsed system tray that keeps status items separate from the app dock.
 */
Item {
    id: root

    property var popupScreen: null
    property real popupRightMargin: Theme.gap * 2
    property bool menuOpen: false
    property real menuProgress: 0

    readonly property var trayItems: SystemTray.items.values
    readonly property real menuWidth: 260
    readonly property real menuHeight: menuContent.implicitHeight + Theme.panelPadding * 2

    width: labelRow.implicitWidth
    height: 28
    visible: root.trayItems.length > 0

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: -Theme.gap * 1.5
            rightMargin: -Theme.gap * 1.5
        }
        color: trayMouse.containsMouse || root.menuOpen ? Theme.panelSurfaceHover : "transparent"
        radius: Theme.radius
    }

    Row {
        id: labelRow

        anchors.centerIn: parent
        spacing: Theme.gap * 2

        Text {
            color: Theme.red
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
            text: "󰀻"
        }

        Text {
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
            text: "Tray"
        }
    }

    MouseArea {
        id: trayMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.menuOpen = !root.menuOpen
    }

    PanelWindow {
        id: trayWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.menuOpen || trayPanel.progress > 0
        implicitWidth: trayPanel.length + trayPanel.curveRadius
        implicitHeight: trayPanel.depth + trayPanel.curveRadius

        mask: Region {
            item: trayHost
        }

        WlrLayershell.namespace: "quickshell:systemTray"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.popupRightMargin
        }

        Item {
            id: trayHost

            anchors.fill: parent
            visible: trayWindow.visible

            Frame.PulloutPanel {
                id: trayPanel

                anchors {
                    top: parent.top
                    right: parent.right
                }

                requestedOpen: root.menuOpen
                activatorMouseArea: trayMouse
                dismissOnExit: true
                closeDelay: 200
                hoverLeaseDuration: 1200
                duration: 180
                length: root.menuWidth
                depth: root.menuHeight
                backgroundColor: Theme.panelBg
                corner: "topRight"
                curveRadius: Theme.panelRadius

                onProgressChanged: root.menuProgress = trayPanel.progress
                onDismissRequested: root.menuOpen = false

                ColumnLayout {
                    id: menuContent

                    anchors {
                        fill: parent
                        margins: Theme.panelPadding
                    }
                    spacing: Theme.panelItemGap

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelTitleSize
                            font.bold: true
                            text: "System Tray"
                        }

                        Text {
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                            text: root.trayItems.length
                        }
                    }

                    Repeater {
                        model: root.trayItems

                        Rectangle {
                            id: trayRow

                            required property SystemTrayItem modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            color: rowMouse.containsMouse ? Theme.panelSurface : "transparent"
                            radius: Theme.surfaceRadius

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: Theme.gap * 2
                                    rightMargin: Theme.gap * 2
                                }
                                spacing: Theme.panelItemGap

                                IconImage {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    source: trayRow.modelData.icon
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        color: Theme.fg
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelMetaSize
                                        text: trayRow.modelData.title || trayRow.modelData.id
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelCaptionSize
                                        text: trayRow.modelData.tooltipDescription
                                    }
                                }

                                Text {
                                    visible: trayRow.modelData.hasMenu
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    text: "›"
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) {
                                        trayRow.modelData.secondaryActivate();
                                        return;
                                    }

                                    if (mouse.button === Qt.RightButton || trayRow.modelData.onlyMenu) {
                                        const point = trayRow.mapToItem(null, trayRow.width, 0);
                                        trayRow.modelData.display(trayWindow, point.x, point.y);
                                        return;
                                    }

                                    trayRow.modelData.activate();
                                    root.menuOpen = false;
                                }
                                onWheel: wheel => trayRow.modelData.scroll(wheel.angleDelta.y, false)
                            }
                        }
                    }
                }
            }
        }
    }
}
