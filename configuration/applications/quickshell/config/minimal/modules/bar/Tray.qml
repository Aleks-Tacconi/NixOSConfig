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
    property var activeMenu: null
    property real menuProgress: 0

    readonly property var trayItems: SystemTray.items.values
    readonly property real menuWidth: 280
    readonly property real menuHeight: 300

    width: barContent.implicitWidth + Theme.gap * 3
    height: 28
    visible: root.trayItems.length > 0

    onMenuOpenChanged: {
        if (!root.menuOpen)
            root.activeMenu = null;
    }

    Rectangle {
        anchors.fill: parent
        color: trayMouse.containsMouse || root.menuOpen ? Theme.panelSurfaceHover : "transparent"
        radius: Theme.radius
    }

    Text {
        id: barContent

        anchors.centerIn: parent
        color: Theme.red
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
        text: "󰍜"
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

                Item {
                    visible: root.activeMenu === null
                    anchors {
                        fill: parent
                        margins: Theme.panelPadding
                    }

                    ColumnLayout {
                        id: mainListLayout
                        anchors.fill: parent
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

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Flickable {
                                id: mainListScroll

                                anchors {
                                    fill: parent
                                    rightMargin: Theme.gap * 2
                                }
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                contentWidth: width
                                contentHeight: mainListContent.implicitHeight
                                interactive: contentHeight > height

                                ColumnLayout {
                                    id: mainListContent

                                    width: mainListScroll.width
                                    spacing: Theme.panelItemGap

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
                                                    source: trayRow.modelData.icon.length > 0 ? trayRow.modelData.icon : "application-x-executable"
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
                                                        text: trayRow.modelData.title || trayRow.modelData.id || "Tray Item"
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        visible: text.length > 0
                                                        color: Theme.muted
                                                        elide: Text.ElideRight
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.panelCaptionSize
                                                        text: trayRow.modelData.tooltipDescription || trayRow.modelData.tooltipTitle || ""
                                                    }
                                                }

                                                Text {
                                                    visible: trayRow.modelData.hasMenu
                                                    color: rowMouse.containsMouse ? Theme.red : Theme.muted
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSize
                                                    font.bold: rowMouse.containsMouse
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

                                                    if ((mouse.button === Qt.RightButton || trayRow.modelData.onlyMenu)
                                                            && trayRow.modelData.hasMenu) {
                                                        root.activeMenu = trayRow.modelData.menu;
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

                            Frame.PanelScrollIndicator {
                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    bottom: parent.bottom
                                    rightMargin: 1
                                }
                                flickable: mainListScroll
                            }
                        }
                    }
                }

                Item {
                    visible: root.activeMenu !== null
                    anchors {
                        fill: parent
                        margins: Theme.panelPadding
                    }

                    Flickable {
                        id: trayMenuScroll

                        anchors {
                            fill: parent
                            rightMargin: Theme.gap * 2
                        }
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: trayMenuView.implicitHeight
                        interactive: contentHeight > height

                        Frame.PanelMenuView {
                            id: trayMenuView

                            width: trayMenuScroll.width
                            menu: root.activeMenu
                            showRootBack: true
                            rootBackLabel: "Back to tray"
                            onActivated: root.menuOpen = false
                            onRootBackRequested: root.activeMenu = null
                        }
                    }

                    Frame.PanelScrollIndicator {
                        anchors {
                            top: parent.top
                            right: parent.right
                            bottom: parent.bottom
                            rightMargin: 1
                        }
                        flickable: trayMenuScroll
                    }
                }
            }
        }
    }
}
