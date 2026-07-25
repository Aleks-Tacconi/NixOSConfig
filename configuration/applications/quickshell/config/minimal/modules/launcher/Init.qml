pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Centered application launcher and picker popup.
 */
Scope {
    id: root

    property bool open: false
    property string mode: "applications"
    property real panelWidth: 920
    property real panelDepth: 550
    property real previewWidth: 360
    property int revealDuration: 180
    property int targetMonitorId: -1

    function show() {
        root.targetMonitorId = Hyprland.focusedMonitor?.id ?? -1;
        root.mode = "applications";
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function toggle() {
        if (root.open)
            root.hide();
        else
            root.show();
    }

    function nextMode() {
        if (root.mode === "applications")
            root.mode = "files";
        else if (root.mode === "files")
            root.mode = "emoji";
        else if (root.mode === "emoji")
            root.mode = "clipboard";
        else
            root.mode = "applications";
    }

    function setMode(mode) {
        root.mode = mode;
    }

    function isTargetScreen(screen) {
        const monitor = Hyprland.monitorFor(screen);

        if (monitor === null || monitor === undefined)
            return false;

        return root.targetMonitorId >= 0 ? monitor.id === root.targetMonitorId : monitor.focused;
    }

    IpcHandler {
        target: "appLauncher"

        function open() {
            root.show();
        }

        function close() {
            root.hide();
        }

        function toggle() {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "appLauncher"
        description: "Open the Quickshell application launcher"

        onPressed: root.toggle()
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenRoot

            required property var modelData

            readonly property bool wantsOpen: root.open && root.isTargetScreen(screenRoot.modelData)

            PanelWindow {
                id: launcherWindow

                screen: screenRoot.modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: screenRoot.wantsOpen || launcherPanel.progress > 0
                mask: Region {
                    item: launcherPanel
                }

                WlrLayershell.namespace: "quickshell:appLauncher"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: screenRoot.wantsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                margins {
                    top: 0
                    left: 0
                    right: 0
                    bottom: 0
                }

                Item {
                    id: launcherHost

                    anchors.fill: parent
                    clip: false
                    visible: launcherWindow.visible

                    Frame.PulloutPanel {
                        id: launcherPanel

                        edge: "bottom"
                        requestedOpen: screenRoot.wantsOpen
                        autoClose: false
                        duration: root.revealDuration
                        length: Math.min(root.panelWidth, Math.max(420, launcherHost.width - 48))
                        depth: root.panelDepth
                        backgroundColor: Theme.panelBg
                        curveRadius: Theme.panelRadius

                        anchors {
                            centerIn: parent
                        }

                        LauncherContent {
                            id: launcherContent

                            anchors {
                                fill: parent
                                topMargin: Theme.panelPadding
                                leftMargin: Theme.panelPadding
                                rightMargin: Theme.panelPadding
                                bottomMargin: Theme.panelPadding
                            }

                            open: screenRoot.wantsOpen
                            mode: root.mode
                            onRequestClose: root.hide()
                            onRequestModeCycle: root.nextMode()
                            onModeRequested: mode => root.setMode(mode)
                        }
                    }
                }
            }

            PanelWindow {
                id: previewWindow

                screen: screenRoot.modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: screenRoot.wantsOpen && launcherContent.hasPreviewItem
                mask: Region {
                    item: previewPanel
                }

                WlrLayershell.namespace: "quickshell:appLauncherPreview"
                WlrLayershell.layer: WlrLayer.Overlay

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                margins {
                    top: 0
                    left: 0
                    right: 0
                    bottom: 0
                }

                Item {
                    id: previewHost

                    anchors.fill: parent
                    clip: false
                    visible: previewWindow.visible

                    Frame.PulloutPanel {
                        id: previewPanel

                        requestedOpen: screenRoot.wantsOpen && launcherContent.hasPreviewItem
                        autoClose: false
                        duration: root.revealDuration
                        length: root.previewWidth
                        depth: root.panelDepth
                        backgroundColor: Theme.panelBg
                        curveRadius: Theme.panelRadius

                        x: Math.max(Theme.gap * 4, Math.min(previewHost.width - root.previewWidth - Theme.gap * 4, (previewHost.width + launcherPanel.length) / 2 + Theme.gap * 4))
                        y: (previewHost.height - root.panelDepth) / 2

                        LauncherFilePreview {
                            anchors {
                                fill: parent
                                margins: Theme.panelPadding
                            }

                            fileItem: launcherContent.selectedPreviewItem
                        }
                    }
                }
            }
        }
    }
}
