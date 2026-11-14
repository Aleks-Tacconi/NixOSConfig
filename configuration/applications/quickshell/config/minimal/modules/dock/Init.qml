pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import "../frame" as Frame
import "../../theme"

/**
 * Top-bar dock combining open and pinned applications with tray icons and a unified popup.
 */
Item {
    id: root

    property var popupScreen: null
    property real maxWidth: 260
    property real buttonSize: 30
    property real dockGap: Theme.gap
    property real hoverOverflow: Theme.gap
    property real popupWidth: 340
    property real popupMaxHeight: Math.max(0, Math.min(640, (root.popupScreen?.height ?? 900) - Theme.barHeight - Theme.popupGap - Theme.gap * 6))
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

    readonly property int appCount: DockData.appGroups.length + dockItems.trayCount
    readonly property real fullWidth: dockItems.fullWidth
    readonly property string activeGroupKey: root.hoveredApp?.appId
        ? DockData.normalizedAppId(root.hoveredApp.appId)
        : ""
    readonly property var activeTrayItem: root.hoveredApp?.tray?.item ?? null

    width: Math.min(root.maxWidth, root.fullWidth)
    height: Theme.barHeight
    visible: root.appCount > 0 && root.maxWidth > 0
    clip: false

    Connections {
        target: DockData

        function onAppGroupsChanged() {
            root.refreshDisplayedApp();
        }
    }

    Connections {
        target: SystemTray.items

        function onValuesChanged() {
            root.refreshDisplayedApp();
        }
    }

    function groupIdentity(appGroup) {
        if (!appGroup)
            return "";
        const appId = DockData.normalizedAppId(appGroup.appId ?? "");
        if (appId.length > 0)
            return `app:${appId}`;
        const trayId = String(appGroup.tray?.item?.id ?? "");
        return trayId.length > 0 ? `tray:${trayId}` : "";
    }

    function findLatestGroup(identity) {
        for (const group of dockItems.groups) {
            if (root.groupIdentity(group) === identity)
                return group;
        }
        for (const entry of dockItems.remainingTrayEntries) {
            const trayGroup = dockItems.trayGroupForEntry(entry);
            if (root.groupIdentity(trayGroup) === identity)
                return trayGroup;
        }
        return null;
    }

    function displayGroup(appGroup) {
        if (!appGroup) {
            root.displayedApp = null;
            return;
        }
        root.displayedApp = {
            appId: appGroup.appId ?? "",
            pinned: appGroup.pinned ?? false,
            toplevels: (appGroup.toplevels ?? []).slice(),
            active: appGroup.active ?? false,
            tray: appGroup.tray ?? null,
            desktopEntry: appGroup.desktopEntry ?? null
        };
    }

    function refreshDisplayedApp() {
        const current = root.displayedApp ?? root.hoveredApp;
        const identity = root.groupIdentity(current);
        if (identity.length === 0)
            return;

        const latestGroup = root.findLatestGroup(identity);
        if (latestGroup) {
            root.displayGroup(latestGroup);
            popupHeightSync.restart();
            return;
        }

        root.dismissPopup();
    }

    function openForApp(appGroup, activatorMouseArea) {
        const nextIdentity = root.groupIdentity(appGroup);
        const currentIdentity = root.groupIdentity(root.displayedApp);
        if (nextIdentity.length > 0 && nextIdentity === currentIdentity && root.hoveredApp !== null) {
            root.dismissPopup();
            return;
        }

        root.forcePopupClose = false;
        appPanel.resetMenu();
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

    Timer {
        id: popupHeightSync

        interval: root.hoveredApp !== null ? 40 : 0
        onTriggered: {
            root.currentPopupHeight = root.desiredPopupHeight();
            if (root.pendingOpenApp !== null) {
                root.hoveredApp = root.pendingOpenApp;
                root.hoveredActivator = root.pendingOpenActivator;
                root.pendingOpenApp = null;
                root.pendingOpenActivator = null;
            }
        }
    }

    Frame.BarPopupWindow {
        id: pulloutWindow

        popupScreen: root.popupScreen
        namespace: "quickshell:topBarDockPullout"
        alignEdge: "right"
        edgeMargin: root.popupRightMargin
        requestedOpen: root.hoveredApp !== null
        forceClose: root.forcePopupClose
        activatorMouseArea: root.hoveredActivator
        closeDelay: root.closeDelay
        hoverLeaseDuration: 900
        duration: root.revealDuration
        panelWidth: root.popupWidth
        panelDepth: root.currentPopupHeight
        contentPadding: root.pulloutPadding
        onDismissRequested: root.dismissPopup()

        onProgressChanged: {
            if (pulloutWindow.progress > 0)
                return;
            root.hoveredApp = null;
            root.hoveredActivator = null;
            root.displayedApp = null;
            root.currentPopupHeight = root.minPopupHeight;
            root.forcePopupClose = false;
        }

        DockAppPanel {
            id: appPanel

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            maxBodyHeight: Math.max(120, root.popupMaxHeight - root.pulloutPadding * 2 - 44)
            appGroup: root.displayedApp ?? ({
                appId: "",
                toplevels: [],
                tray: null,
                desktopEntry: null
            })
            dataSource: DockData
            previewsActive: pulloutWindow.effectiveOpen && pulloutWindow.progress >= 0.95
            onImplicitHeightChanged: popupHeightSync.restart()
            onDismissRequested: root.dismissPopup()
        }
    }

    DockItems {
        id: dockItems

        anchors.fill: parent
        anchors.topMargin: Theme.gap
        anchors.bottomMargin: Theme.gap
        dataSource: DockData
        buttonSize: root.buttonSize
        spacing: root.dockGap
        hoverOverflow: root.hoverOverflow
        activeGroupKey: root.activeGroupKey
        activeTrayItem: root.activeTrayItem
        onPopupRequested: (appGroup, activator) => root.openForApp(appGroup, activator)
    }
}
