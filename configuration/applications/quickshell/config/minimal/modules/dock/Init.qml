pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Top-bar dock combining open and pinned applications with tray icons.
 */
Item {
    id: root

    property var popupScreen: null
    property real maxWidth: 260
    property real buttonSize: 30
    property real dockGap: Theme.gap
    property real hoverOverflow: Theme.gap
    property real popupWidth: 340
    property real popupMaxHeight: Math.max(0, Math.min(520, (root.popupScreen?.height ?? 900) - Theme.barHeight - Theme.popupGap - Theme.gap * 6))
    property real popupRightMargin: Theme.gap * 2
    property real pulloutPadding: Theme.panelPadding
    property real minPopupHeight: 70
    property real currentPopupHeight: minPopupHeight
    property int revealDuration: 150
    property int closeDelay: Theme.popupDismissDelay
    property var hoveredApp: null
    property var hoveredActivator: null
    property var displayedApp: null
    property var pendingOpenApp: null
    property var pendingOpenActivator: null
    property bool forcePopupClose: false

    readonly property int appCount: dockData.appGroups.length + dockItems.trayCount
    readonly property real fullWidth: dockItems.fullWidth

    width: Math.min(root.maxWidth, root.fullWidth)
    height: Theme.barHeight
    visible: root.appCount > 0 && root.maxWidth > 0
    clip: false

    DockData {
        id: dockData

        onAppGroupsChanged: root.refreshDisplayedApp()
    }

    function appGroupById(appId) {
        const key = dockData.normalizedAppId(appId)

        return dockData.appGroups.find(group => dockData.normalizedAppId(group.appId) === key) ?? null
    }

    function displayGroup(appGroup) {
        if (!appGroup) {
            root.displayedApp = null
            return
        }

        root.displayedApp = {
            appId: appGroup.appId,
            pinned: appGroup.pinned,
            toplevels: appGroup.toplevels.slice(),
            active: appGroup.active ?? false,
        }
    }

    function refreshDisplayedApp() {
        const appId = root.displayedApp?.appId ?? root.hoveredApp?.appId ?? ""

        if (appId.length === 0)
            return

        const latestGroup = root.appGroupById(appId)

        if (latestGroup) {
            root.displayGroup(latestGroup)
            popupHeightSync.restart()
            return
        }

        root.hoveredApp = null
        root.hoveredActivator = null
        root.displayedApp = null
        popupHeightSync.restart()
    }

    function openForApp(appGroup, activatorMouseArea) {
        dockItems.closeTrayMenu();
        const nextAppId = appGroup?.appId ?? "";
        const displayedAppId = root.displayedApp?.appId ?? "";
        const wasRequestedOpen = root.hoveredApp !== null;

        if (nextAppId === displayedAppId && wasRequestedOpen) {
            root.dismissPopup();
            return;
        }

        root.forcePopupClose = false;
        root.displayGroup(appGroup);
        root.pendingOpenApp = appGroup;
        root.pendingOpenActivator = activatorMouseArea;
        popupHeightSync.restart();
    }

    function dismissPopup() {
        root.forcePopupClose = true;
        root.pendingOpenApp = null;
        root.pendingOpenActivator = null;
        root.hoveredApp = null;
        root.hoveredActivator = null;
    }

    function desiredPopupHeight() {
        return Math.min(root.popupMaxHeight, Math.max(root.minPopupHeight, appPanel.implicitHeight + root.pulloutPadding * 2));
    }

    function syncPopupHeight() {
        root.currentPopupHeight = root.desiredPopupHeight();
    }

    Timer {
        id: popupHeightSync

        interval: 0
        onTriggered: {
            root.syncPopupHeight();
            if (root.pendingOpenApp !== null) {
                root.hoveredApp = root.pendingOpenApp;
                root.hoveredActivator = root.pendingOpenActivator;
                root.pendingOpenApp = null;
                root.pendingOpenActivator = null;
            }
        }
    }

    PanelWindow {
        id: pulloutWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.hoveredApp !== null || pulloutPanel.progress > 0
        implicitWidth: root.popupWidth
        implicitHeight: pulloutPanel.depth
        mask: Region {
            item: pulloutPanel
        }

        WlrLayershell.namespace: "quickshell:topBarDockPullout"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.hoveredApp !== null ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            right: root.popupRightMargin
        }

        Frame.PulloutPanel {
            id: pulloutPanel

            corner: "topRight"
            requestedOpen: root.hoveredApp !== null
            forceClose: root.forcePopupClose
            activatorMouseArea: root.hoveredActivator
            clickDismiss: true
            onDismissRequested: root.dismissPopup()
            closeDelay: root.closeDelay
            hoverLeaseDuration: 700
            duration: root.revealDuration
            length: root.popupWidth
            depth: root.currentPopupHeight
            backgroundColor: Theme.panelBg
            curveRadius: Theme.panelRadius

            onProgressChanged: {
                if (pulloutPanel.progress > 0)
                    return;

                root.hoveredApp = null;
                root.hoveredActivator = null;
                root.displayedApp = null;
                root.currentPopupHeight = root.minPopupHeight;
                root.forcePopupClose = false;
            }

            anchors {
                top: parent.top
                right: parent.right
            }

            Item {
                anchors {
                    fill: parent
                    margins: root.pulloutPadding
                }
                clip: true

                DockAppPanel {
                    id: appPanel

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    appGroup: root.displayedApp ?? ({
                            appId: "",
                            toplevels: []
                        })
                    dataSource: dockData
                    previewsActive: pulloutPanel.effectiveOpen && pulloutPanel.progress >= 0.95
                    onImplicitHeightChanged: popupHeightSync.restart()
                    onDismissRequested: root.dismissPopup()
                }
            }
        }
    }

    DockItems {
        id: dockItems

        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.bottomMargin: Theme.gap
        dataSource: dockData
        popupScreen: root.popupScreen
        popupRightMargin: root.popupRightMargin
        buttonSize: root.buttonSize
        spacing: root.dockGap
        hoverOverflow: root.hoverOverflow
        onPopupRequested: (appGroup, activator) => root.openForApp(appGroup, activator)
        onTrayMenuRequested: root.dismissPopup()
    }
}
