pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../theme"

/**
 * Workspace preview and drop target.
 */
Rectangle {
    id: root

    required property var dataSource
    required property int workspaceId
    required property real screenX
    required property real screenY
    required property real screenWidth
    required property real screenHeight

    property bool newWorkspace: false
    property bool dropActive: false
    property bool compact: false
    property int hoveredWorkspace: -1
    property int dragSourceWorkspace: -1
    property bool draggingWindow: false
    property real compactPreviewWidth: 344
    property real compactPreviewHeight: 190

    readonly property bool activeWorkspace: dataSource.activeWorkspace?.id === root.workspaceId
    readonly property var workspaceMonitor: root.dataSource.monitorForWorkspace(root.workspaceId)
    readonly property real workspaceX: root.workspaceMonitor?.x ?? root.screenX
    readonly property real workspaceY: root.workspaceMonitor?.y ?? root.screenY
    readonly property real workspaceWidth: root.workspaceMonitor?.width ?? root.screenWidth
    readonly property real workspaceHeight: root.workspaceMonitor?.height ?? root.screenHeight
    readonly property var previewToplevels: root.newWorkspace ? [] : root.dataSource.previewToplevelsForWorkspace(root.workspaceId)
    readonly property real previewHeight: root.compact ? root.compactPreviewHeight : 124
    readonly property real previewScale: Math.min(root.previewWidth / Math.max(root.workspaceWidth, 1), root.previewHeight / Math.max(root.workspaceHeight, 1))
    readonly property real previewWidth: root.compact ? root.compactPreviewWidth : Math.round(root.screenWidth * root.previewScale)
    readonly property real scaledWorkspaceWidth: root.workspaceWidth * root.previewScale
    readonly property real scaledWorkspaceHeight: root.workspaceHeight * root.previewScale
    readonly property real scaledWorkspaceX: (root.previewWidth - root.scaledWorkspaceWidth) / 2
    readonly property real scaledWorkspaceY: (root.previewHeight - root.scaledWorkspaceHeight) / 2
    readonly property bool effectiveDropActive: root.dropActive && root.dragSourceWorkspace !== root.workspaceId

    signal clicked
    signal dragEntered
    signal dragExited
    signal dragStateChanged(bool active, int sourceWorkspace)
    signal windowDropped(var toplevel, int workspaceId)

    function iconSourceForWindow(toplevel, appClass) {
        const appId = toplevel?.appId ?? "";
        const desktopEntry = DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? DesktopEntries.heuristicLookup(appClass);

        if (desktopEntry?.icon) {
            const desktopIcon = Quickshell.iconPath(desktopEntry.icon, true);

            if (desktopIcon.length > 0)
                return desktopIcon;
        }

        const names = [appId, appClass];

        for (const name of names) {
            if (name.length <= 0)
                continue;
            const shortName = name.split(".").pop();
            const candidates = [name, name.toLowerCase(), shortName, shortName.toLowerCase(), name.toLowerCase().replace(/\s+/g, "-")];

            for (const candidate of candidates) {
                const source = Quickshell.iconPath(candidate, true);

                if (source.length > 0)
                    return source;
            }
        }

        return "";
    }

    width: root.previewWidth + Theme.gap * 3
    height: root.compact ? root.previewHeight + Theme.gap * 3 : root.previewHeight + 44
    z: root.draggingWindow ? 100 : root.effectiveDropActive ? 10 : 1
    radius: root.compact ? Theme.cardRadius : Theme.surfaceRadius
    color: root.activeWorkspace ? Theme.panelSurfaceHover : Theme.panelSurface
    border.width: 0

    Column {
        anchors {
            fill: parent
            margins: Theme.gap
        }

        spacing: root.compact ? 0 : Theme.gap

        Text {
            visible: !root.compact
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelBodySize
            text: root.newWorkspace ? "New workspace" : `Workspace ${root.workspaceId}`
        }

        Rectangle {
            id: preview

            width: root.previewWidth
            height: root.previewHeight
            radius: Theme.surfaceRadius
            color: "transparent"
            clip: !root.draggingWindow

            Text {
                anchors.centerIn: parent
                z: 0
                color: root.activeWorkspace ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(parent.width, parent.height) * (root.compact ? 0.62 : 0.7)
                font.bold: true
                opacity: root.activeWorkspace ? 0.22 : 0.16
                text: root.newWorkspace ? "+" : root.workspaceId
            }

            Repeater {
                model: root.previewToplevels

                delegate: Item {
                    id: windowPreview

                    required property var modelData

                    readonly property var previewToplevel: modelData
                    readonly property var hyprlandClient: root.dataSource.clientForToplevel(modelData)
                    readonly property string appClass: hyprlandClient?.class ?? ""
                    readonly property string appTitle: hyprlandClient?.title ?? appClass
                    readonly property string iconSource: root.iconSourceForWindow(windowPreview.previewToplevel, appClass)
                    readonly property real baseX: root.scaledWorkspaceX + ((hyprlandClient?.at?.[0] ?? root.workspaceX) - root.workspaceX) * root.previewScale
                    readonly property real baseY: root.scaledWorkspaceY + ((hyprlandClient?.at?.[1] ?? root.workspaceY) - root.workspaceY) * root.previewScale
                    readonly property real titleBarHeight: 18
                    readonly property real contentWidth: Math.max(12, (hyprlandClient?.size?.[0] ?? 0) * root.previewScale)
                    readonly property real contentHeight: Math.max(10, (hyprlandClient?.size?.[1] ?? 0) * root.previewScale)

                    width: windowPreview.contentWidth
                    height: windowPreview.contentHeight + windowPreview.titleBarHeight
                    x: baseX + (previewDragHandler.active ? previewDragHandler.activeTranslation.x : 0)
                    y: Math.max(0, baseY - windowPreview.titleBarHeight) + (previewDragHandler.active ? previewDragHandler.activeTranslation.y : 0)
                    z: previewDragHandler.active ? 60 : 2
                    scale: previewDragHandler.active ? 0.92 : 1

                    Drag.active: previewDragHandler.active
                    Drag.source: windowPreview
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }

                    Behavior on x {
                        enabled: !previewDragHandler.active
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }

                    Behavior on y {
                        enabled: !previewDragHandler.active
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }

                    Item {
                        id: appPreviewContent

                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }

                        height: windowPreview.contentHeight

                        ScreencopyView {
                            anchors.fill: parent
                            captureSource: windowPreview.previewToplevel
                            constraintSize: Qt.size(Math.round(parent.width), Math.round(parent.height))
                            live: true
                        }

                        IconImage {
                            anchors.centerIn: parent
                            visible: windowPreview.iconSource.length > 0
                            width: Math.max(16, Math.min(parent.width, parent.height) * 0.38)
                            height: width
                            opacity: 0.86
                            source: windowPreview.iconSource
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: windowPreview.iconSource.length === 0
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.max(12, Math.min(parent.width, parent.height) * 0.32)
                            font.bold: true
                            opacity: 0.8
                            text: windowPreview.appClass.length > 0 ? windowPreview.appClass[0].toUpperCase() : "?"
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        z: 4
                        height: windowPreview.titleBarHeight
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: 0

                        Text {
                            anchors {
                                fill: parent
                                leftMargin: 5
                                rightMargin: 5
                            }

                            color: Theme.fg
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            verticalAlignment: Text.AlignVCenter
                            text: windowPreview.appTitle
                        }
                    }

                    DragHandler {
                        id: previewDragHandler

                        target: null
                        cursorShape: Qt.OpenHandCursor

                        onActiveChanged: {
                            if (active) {
                                root.draggingWindow = true;
                                root.dragStateChanged(true, root.workspaceId);
                                return;
                            }

                            if (root.hoveredWorkspace > 0 && root.hoveredWorkspace !== root.workspaceId)
                                root.windowDropped(windowPreview.previewToplevel, root.hoveredWorkspace);

                            root.draggingWindow = false;
                            root.dragStateChanged(false, root.workspaceId);
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.newWorkspace && root.previewToplevels.length === 0
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: root.compact ? Theme.fontSize + 6 : Theme.fontSize + 10
                text: "+"
            }

            Rectangle {
                anchors.fill: parent
                visible: root.effectiveDropActive
                z: 1
                color: Theme.red
                opacity: 0.12
            }
        }
    }

    TapHandler {
        onTapped: root.clicked()
    }

    DropArea {
        anchors.fill: parent
        onEntered: root.dragEntered()
        onExited: root.dragExited()
        onDropped: drop => {
            const source = drop.source;

            if (source?.previewToplevel)
                root.windowDropped(source.previewToplevel, root.workspaceId);
        }
    }
}
