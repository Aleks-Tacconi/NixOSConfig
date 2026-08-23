pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"
import "../.." as ShellConfig

/**
 * Centered application launcher and picker popup.
 */
Scope {
    id: root

    property bool open: false
    readonly property var enabledModes: ShellConfig.Config.launcher.enabledModes
    property string mode: root.enabledModes[0]
    property real panelWidth: 920
    property real panelDepth: 550
    property real previewWidth: 360
    property int revealDuration: 150
    property int targetMonitorId: -1

    function show() {
        root.targetMonitorId = Hyprland.focusedMonitor?.id ?? -1;
        root.mode = root.enabledModes[0];
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

    function nextMode(direction = 1) {
        const currentIndex = root.enabledModes.indexOf(root.mode);
        root.mode = root.enabledModes[(currentIndex + direction + root.enabledModes.length) % root.enabledModes.length];
    }

    function setMode(mode) {
        if (root.enabledModes.includes(mode))
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
            property var retainedPreviewItem: null

            readonly property bool wantsOpen: root.open && root.isTargetScreen(screenRoot.modelData)
            readonly property bool previewFits: (launcherHost.width - launcherPanel.length) / 2 >= root.previewWidth + Theme.gap * 4

            Connections {
                target: launcherContent

                function onSelectedPreviewItemChanged() {
                    if (launcherContent.selectedPreviewItem !== null)
                        screenRoot.retainedPreviewItem = launcherContent.selectedPreviewItem;
                }
            }

            PanelWindow {
                id: launcherWindow

                screen: screenRoot.modelData
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: screenRoot.wantsOpen || launcherPanel.progress > 0
                mask: Region {
                    item: launcherHost
                }

                WlrLayershell.namespace: "quickshell:appLauncher"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: screenRoot.wantsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            const outside = mouse.x < launcherPanel.x
                                || mouse.x > launcherPanel.x + launcherPanel.width
                                || mouse.y < launcherPanel.y
                                || mouse.y > launcherPanel.y + launcherPanel.height;
                            if (outside)
                                root.hide();
                        }
                    }

                    Frame.PulloutPanel {
                        id: launcherPanel

                        edge: "bottom"
                        requestedOpen: screenRoot.wantsOpen
                        autoClose: false
                        duration: root.revealDuration
                        length: Math.min(root.panelWidth, Math.max(0, launcherHost.width - 48))
                        depth: Math.min(root.panelDepth, Math.max(0, launcherHost.height - 48))
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
                            enabledModes: root.enabledModes
                            maxVisibleRows: Math.max(2, Math.min(6, Math.floor((launcherPanel.depth - 138 + Theme.gap) / (64 + Theme.gap))))
                            onRequestClose: root.hide()
                            onRequestModeCycle: direction => root.nextMode(direction)
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
                visible: screenRoot.previewFits && ((screenRoot.wantsOpen && launcherContent.hasPreviewItem) || previewPanel.progress > 0)
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

                        requestedOpen: screenRoot.wantsOpen && screenRoot.previewFits && launcherContent.hasPreviewItem
                        autoClose: false
                        duration: root.revealDuration
                        length: root.previewWidth
                        depth: launcherPanel.depth
                        backgroundColor: Theme.panelBg
                        curveRadius: Theme.panelRadius

                        x: Math.max(Theme.gap * 4, Math.min(previewHost.width - root.previewWidth - Theme.gap * 4, (previewHost.width + launcherPanel.length) / 2 + Theme.gap * 4))
                        y: (previewHost.height - previewPanel.depth) / 2

                        LauncherFilePreview {
                            anchors {
                                fill: parent
                                margins: Theme.panelPadding
                            }

                            fileItem: screenRoot.retainedPreviewItem
                        }
                    }
                }
            }
        }
    }
}
