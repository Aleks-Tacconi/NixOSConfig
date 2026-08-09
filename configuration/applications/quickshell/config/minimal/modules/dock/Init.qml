pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Compact top-bar dock with click popups for app windows.
 */
Item {
    id: root

    property var popupScreen: null
    property real maxWidth: 260
    property real buttonSize: 30
    property real dockGap: Theme.gap
    property real hoverOverflow: Theme.gap
    property real popupWidth: 360
    property real popupMaxHeight: Math.max(540, (root.popupScreen?.height ?? 900) - Theme.barHeight - Theme.popupGap - Theme.gap * 6)
    property real popupRightMargin: Theme.gap * 2
    property real pulloutPadding: Theme.panelPadding
    property real minPopupHeight: 70
    property real currentPopupHeight: minPopupHeight
    property int revealDuration: 180
    property int closeDelay: 120
    property var hoveredApp: null
    property var hoveredActivator: null
    property var displayedApp: null
    property bool contentVisible: false
    property bool fadeInAfterResize: false

    readonly property int appCount: dockData.appGroups.length
    readonly property real fullWidth: Math.max(0, dockRow.implicitWidth + root.hoverOverflow * 2)

    width: Math.min(root.maxWidth, root.fullWidth)
    height: Theme.barHeight
    visible: root.appCount > 0
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
        root.contentVisible = false
        popupHeightSync.restart()
    }

    function queueDisplayedAppRefresh() {
        dockRefreshAfterClose.restart()
    }

    function openForApp(appGroup, activatorMouseArea) {
        const nextAppId = appGroup?.appId ?? "";
        const displayedAppId = root.displayedApp?.appId ?? "";
        const alreadyOpen = pulloutPanel.progress > 0;

        root.hoveredApp = appGroup;
        root.hoveredActivator = activatorMouseArea;

        if (nextAppId === displayedAppId && root.contentVisible)
            return;

        root.fadeInAfterResize = !alreadyOpen;
        root.contentVisible = alreadyOpen;
        root.displayGroup(appGroup);
        popupHeightSync.restart();
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
            if (root.fadeInAfterResize) {
                contentFadeIn.restart();
                return;
            }

            root.contentVisible = true;
        }
    }

    Timer {
        id: dockRefreshAfterClose

        interval: 300
        repeat: false
        onTriggered: root.refreshDisplayedApp()
    }

    Timer {
        id: contentFadeIn

        interval: 20
        onTriggered: {
            root.fadeInAfterResize = false;
            root.contentVisible = true;
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
            activatorMouseArea: root.hoveredActivator
            autoClose: true
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
                root.contentVisible = false;
                root.fadeInAfterResize = false;
                root.currentPopupHeight = root.minPopupHeight;
            }

            anchors {
                top: parent.top
                right: parent.right
            }

            Flickable {
                anchors {
                    fill: parent
                    margins: root.pulloutPadding
                }

                clip: true
                opacity: root.contentVisible ? 1 : 0
                visible: opacity > 0
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: appPanel.implicitHeight
                interactive: contentHeight > height

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.contentVisible ? 110 : 0
                        easing.type: Easing.OutCubic
                    }
                }

                DockAppPanel {
                    id: appPanel

                    width: parent.width
                    appGroup: root.displayedApp ?? ({
                            appId: "",
                            toplevels: []
                        })
                    dataSource: dockData
                    onImplicitHeightChanged: popupHeightSync.restart()
                    onWindowCloseRequested: root.queueDisplayedAppRefresh()
                }
            }
        }
    }

    Flickable {
        anchors {
            fill: parent
            topMargin: 4
            bottomMargin: 4
        }

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: root.fullWidth
        contentHeight: height
        interactive: contentWidth > width

        Row {
            id: dockRow

            x: root.hoverOverflow
            y: (parent.height - height) / 2
            height: root.buttonSize
            spacing: root.dockGap

            Repeater {
                model: dockData.appGroups

                delegate: DockAppButton {
                    required property var modelData

                    width: root.buttonSize
                    height: root.buttonSize
                    appGroup: modelData
                    dataSource: dockData

                    onPopupRequested: (appGroup, activatorMouseArea) => root.openForApp(appGroup, activatorMouseArea)
                }
            }
        }
    }
}
