pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"

/**
 * Standalone workspace overview module.
 */
Scope {
    id: root

    property bool open: false
    property string anchorScreenKey: ""
    property int revealDuration: 320

    function show() {
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function toggle() {
        root.open = !root.open;
    }

    function screenKey(screen) {
        return screen.name ?? `${screen.x},${screen.y}:${screen.width}x${screen.height}`;
    }

    function isAnchorScreen(screen) {
        return root.anchorScreenKey.length > 0 && root.anchorScreenKey === root.screenKey(screen);
    }

    WorkspaceData {
        id: workspaceData
    }

    Variants {
        model: Quickshell.screens

        Loader {
            id: overlayLoader

            required property var modelData

            active: true

            sourceComponent: PanelWindow {
                id: overlay

                property bool panelHovered: false
                property bool panelOpen: false
                readonly property bool anchorHovered: root.isAnchorScreen(overlayLoader.modelData)
                readonly property bool wantsOpen: root.open || anchorHovered || panelHovered
                readonly property real panelHeight: Math.min(552, Math.round(overlayLoader.modelData.height * 0.38))

                screen: overlayLoader.modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: wantsOpen || panelOpen || overview.revealProgress > 0
                implicitHeight: panelHeight

                onWantsOpenChanged: {
                    if (wantsOpen) {
                        closeTimer.stop();
                        panelOpen = true;
                    } else {
                        closeTimer.start();
                    }
                }

                WlrLayershell.namespace: "quickshell:workspaceView"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                anchors {
                    top: true
                    left: true
                    right: true
                }

                margins {
                    top: Theme.barHeight
                    left: 0
                    right: 0
                }

                Timer {
                    id: closeTimer

                    interval: 280
                    onTriggered: overlay.panelOpen = false
                }

                Item {
                    anchors.fill: parent
                    clip: false
                    visible: overlay.visible

                    OverviewContent {
                        id: overview

                        width: parent.width
                        height: overlay.panelHeight
                        panelOpen: overlay.panelOpen
                        panelDuration: root.revealDuration
                        dataSource: workspaceData
                        screenX: overlayLoader.modelData.x
                        screenY: overlayLoader.modelData.y
                        screenWidth: overlayLoader.modelData.width
                        screenHeight: overlayLoader.modelData.height

                        onContainsMouseChanged: overlay.panelHovered = containsMouse
                        onRequestClose: root.hide()
                    }
                }
            }
        }
    }
}
