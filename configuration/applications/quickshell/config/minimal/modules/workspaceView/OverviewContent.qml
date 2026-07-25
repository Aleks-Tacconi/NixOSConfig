pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Centered workspace overview with a floating workspace tray.
 */
Rectangle {
    id: root

    required property var dataSource
    required property bool panelOpen
    required property real screenX
    required property real screenY
    required property real screenWidth
    required property real screenHeight

    property bool draggingWindow: false
    property int hoveredWorkspace: -1
    property int dragSourceWorkspace: -1
    property int panelDuration: 160
    property real padding: 38

    readonly property bool containsMouse: stageFrame.panelHovered
    readonly property real revealProgress: stageFrame.progress
    readonly property real sizeScale: Math.min(1, Math.max(0.72, Math.min(root.screenWidth / 2560, root.screenHeight / 1440)))
    readonly property list<int> workspaceList: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    readonly property int activeWorkspaceId: root.dataSource.activeWorkspace?.id ?? 0
    readonly property int activeWindowCount: root.activeWorkspaceId > 0 ? root.dataSource.toplevelsForWorkspace(root.activeWorkspaceId).length : 0

    signal requestClose

    color: "transparent"
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.requestClose();
            event.accepted = true;
        }
    }

    Timer {
        id: refreshTimer

        interval: 120
        onTriggered: root.dataSource.updateAll()
    }

    MouseArea {
        anchors {
            fill: parent
        }

        onClicked: mouse => {
            const insideStage = mouse.x >= stageFrame.x && mouse.x <= stageFrame.x + stageFrame.width && mouse.y >= stageFrame.y && mouse.y <= stageFrame.y + stageFrame.height;

            if (!insideStage)
                root.requestClose();
        }
    }

    Frame.PulloutPanel {
        id: stageFrame

        edge: "top"
        requestedOpen: root.panelOpen
        autoClose: false
        duration: root.panelDuration
        length: Math.min(root.width - 48, stageContent.implicitWidth + root.padding * root.sizeScale * 2)
        depth: Math.min(root.height - 28, stageContent.implicitHeight + root.padding * root.sizeScale * 2)
        backgroundColor: Theme.panelBg
        curveRadius: Theme.panelRadius

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        Column {
            id: stageContent

            z: 3
            anchors.centerIn: parent
            spacing: Theme.gap * 4 * root.sizeScale

            Row {
                id: overviewStatus

                width: workspaceGrid.implicitWidth
                height: 30 * root.sizeScale
                spacing: Theme.gap * 3

                Text {
                    id: activeLabel

                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    text: root.activeWorkspaceId > 0 ? `Workspace ${root.activeWorkspaceId}` : "Workspaces"
                }

                Text {
                    id: windowLabel

                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    text: root.activeWindowCount === 1 ? "1 window" : `${root.activeWindowCount} windows`
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(40, parent.width - activeLabel.implicitWidth - windowLabel.implicitWidth - hintLabel.implicitWidth - parent.spacing * 3)
                    height: 1
                    color: Theme.darkRed
                }

                Text {
                    id: hintLabel

                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    text: root.draggingWindow ? "Drop to move" : "Drag windows between workspaces"
                }
            }

            Grid {
                id: workspaceGrid

                columns: 5
                rows: 2
                rowSpacing: Theme.gap * 4 * root.sizeScale
                columnSpacing: Theme.gap * 4 * root.sizeScale

                Repeater {
                    model: root.workspaceList

                    delegate: WorkspaceCard {
                        required property int index
                        required property int modelData

                        dataSource: root.dataSource
                        workspaceId: modelData
                        newWorkspace: false
                        dropActive: root.hoveredWorkspace === modelData && root.dragSourceWorkspace !== modelData
                        hoveredWorkspace: root.hoveredWorkspace
                        dragSourceWorkspace: root.dragSourceWorkspace
                        screenX: root.screenX
                        screenY: root.screenY
                        screenWidth: root.screenWidth
                        screenHeight: root.screenHeight
                        compact: true
                        compactPreviewWidth: 344 * root.sizeScale
                        compactPreviewHeight: 190 * root.sizeScale

                        onClicked: {
                            root.requestClose();
                            Hyprland.dispatch(`workspace ${workspaceId}`);
                        }

                        onDragEntered: {
                            if (root.dragSourceWorkspace === workspaceId)
                                return;
                            root.hoveredWorkspace = workspaceId;
                        }

                        onDragExited: {
                            if (root.hoveredWorkspace === workspaceId)
                                root.hoveredWorkspace = -1;
                        }

                        onDragStateChanged: (active, sourceWorkspace) => {
                            root.draggingWindow = active;
                            root.dragSourceWorkspace = active ? sourceWorkspace : -1;

                            if (!active)
                                root.hoveredWorkspace = -1;
                        }

                        onWindowDropped: (toplevel, workspaceId) => {
                            if (workspaceId === root.dragSourceWorkspace)
                                return;
                            const client = root.dataSource.clientForToplevel(toplevel);

                            if (client) {
                                Hyprland.dispatch(`movetoworkspacesilent ${workspaceId}, address:${client.address}`);
                                refreshTimer.restart();
                            }

                            root.hoveredWorkspace = -1;
                        }
                    }
                }
            }
        }
    }
}
