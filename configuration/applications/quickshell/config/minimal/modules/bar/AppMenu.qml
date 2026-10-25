pragma ComponentBehavior: Bound

import QtQuick
import "app-menu-actions.js" as Actions
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../.." as ShellConfig
import "../../theme"
import "../frame" as Frame

/**
 * Native menu entries exported by the focused application.
 */
Item {
    id: root

    required property var popupScreen
    required property var parentWindow

    property real maxWidth: 340
    property real maxPopupDepth: Math.max(0, Math.min(520, (root.popupScreen?.height ?? 900) - Theme.barHeight - Theme.popupGap - Theme.gap * 6))
    property real popupLeftMargin: Theme.gap * 2
    property int actionGeneration: 0
    property string actionState: "idle"
    property var actionRequest: null
    property var actionPresentation: null
    property var pendingWindowRequest: null
    property var pendingGtkRequest: null
    property var deferredGtkResult: null
    property var pendingActivationRequest: null
    property int pendingNativeProbePid: 0
    property bool actionOpenRequested: false
    property bool presentationReusable: false

    readonly property bool actionsOpen: root.actionState === "open"
    readonly property bool actionResolving: root.actionState === "resolving-window"
        || root.actionState === "resolving-gtk"
    readonly property bool actionPresentationActive: root.actionState === "ready"
        || root.actionsOpen
        || root.actionState === "closing"
    readonly property var actionTarget: root.actionRequest?.target ?? root.actionPresentation?.target ?? null
    readonly property var toplevel: root.actionTarget ?? ToplevelManager.activeToplevel
    readonly property var ipcWindow: {
        if (root.actionPresentation !== null)
            return root.actionPresentation.ipcWindow;
        if (root.actionRequest?.pid > 0)
            return root.actionRequest.ipcWindow;

        const liveWindow = Hyprland.activeToplevel?.lastIpcObject;
        if (Actions.ipcMatchesApp(liveWindow, root.appId))
            return liveWindow;

        return {};
    }
    readonly property int activePid: Number(root.ipcWindow.pid ?? 0)
    readonly property var nativeMenu: {
        const revision = AppMenuRegistrar.revision;
        return ShellConfig.Config.appMenu.nativeMenus && root.activePid > 0
            ? AppMenuRegistrar.menuForPid(root.activePid)
            : null;
    }
    readonly property bool hasNativeMenu: root.nativeMenu !== null
    readonly property string appId: root.actionPresentation?.appId
        ?? root.actionRequest?.appId
        ?? Actions.toplevelAppId(root.toplevel)
    readonly property var desktopEntry: root.actionPresentation?.desktopEntry
        ?? root.actionRequest?.desktopEntry
        ?? root.lookupDesktopEntry(root.appId)
    readonly property var actionItems: root.actionPresentation?.actionItems ?? []
    readonly property var specificActionItems: {
        const items = root.actionItems;
        const result = [];
        for (let i = 0; i < items.length; i++) {
            if (!Actions.isNewWindowActionTitle(items[i].title))
                result.push(items[i]);
        }
        return result;
    }
    readonly property bool hasExplicitNewWindowAction: {
        for (let i = 0; i < root.actionItems.length; i++) {
            if (Actions.isNewWindowActionTitle(root.actionItems[i].title))
                return true;
        }
        return false;
    }
    readonly property bool canLaunchNewWindow: root.desktopEntry !== null
        || (root.ipcWindow?.class?.length ?? 0) > 0
        || root.hasExplicitNewWindowAction
    readonly property bool hasActionRows: root.toplevel !== null
    readonly property string appName: root.actionPresentation?.appName
        ?? root.actionRequest?.appName
        ?? root.entryName(root.desktopEntry, root.appId)
    readonly property string iconSource: root.actionPresentation?.iconSource
        ?? root.actionRequest?.iconSource
        ?? root.entryIcon(root.desktopEntry)

    visible: ShellConfig.Config.appMenu.enable && root.toplevel !== null && root.maxWidth > 0
    width: visible ? Math.min(root.maxWidth, menuRow.implicitWidth) : 0
    height: Theme.barHeight
    clip: false

    Component.onCompleted: {
        root.queueNativeMenuProbe();
        Qt.callLater(() => root.prefetchActions());
    }
    onActivePidChanged: root.queueNativeMenuProbe()

    onActionStateChanged: {
        if (root.actionsOpen)
            nativeMenuView.reset();
    }

    Connections {
        target: root.actionTarget
        enabled: root.actionState !== "idle" && root.actionTarget !== null
        ignoreUnknownSignals: true

        function onClosed() {
            root.invalidateActionTarget();
        }

        function onDestroyed() {
            root.invalidateActionTarget();
        }
    }

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            const active = ToplevelManager.activeToplevel;
            if (active !== null && root.actionTarget !== null && active !== root.actionTarget)
                root.invalidateActionTarget();

            Qt.callLater(() => root.prefetchActions());
        }
    }

    function prefetchActions() {
        const active = ToplevelManager.activeToplevel;
        if (active === null || root.actionsOpen || root.actionState === "closing")
            return;
        if (root.actionTarget === active && (root.actionResolving || root.actionState === "ready"))
            return;

        root.beginActionRequest(false);
    }

    function queueNativeMenuProbe() {
        const pid = root.activePid;
        if (!ShellConfig.Config.appMenu.nativeMenus || pid <= 0 || root.nativeMenu !== null)
            return;

        root.pendingNativeProbePid = pid;
        root.startPendingNativeMenuProbe();
    }

    function startPendingNativeMenuProbe() {
        if (backend.qtMenuProbeProcess.running || root.pendingNativeProbePid <= 0)
            return;

        const pid = root.pendingNativeProbePid;
        root.pendingNativeProbePid = 0;
        if (pid !== root.activePid)
            return;

        backend.qtMenuProbeProcess.probedPid = pid;
        backend.qtMenuProbeProcess.exec(["quickshell-qt-menu", String(pid)]);
    }

    function finishNativeMenuProbe(pid, exitCode, output) {
        if (exitCode !== 0 || pid !== root.activePid)
            return;

        try {
            const endpoint = JSON.parse(output);
            if (endpoint !== null
                    && typeof endpoint.service === "string" && endpoint.service.startsWith(":")
                    && typeof endpoint.path === "string" && endpoint.path.startsWith("/"))
                AppMenuRegistrar.registerMenuForPid(pid, endpoint.service, endpoint.path);
        } catch (error) {
            return;
        }
    }





    function lookupDesktopEntry(appId) {
        return DesktopEntries.byId(appId)
            ?? DesktopEntries.heuristicLookup(appId)
            ?? (root.ipcWindow?.class ? DesktopEntries.heuristicLookup(root.ipcWindow.class) : null)
            ?? (root.ipcWindow?.initialClass ? DesktopEntries.heuristicLookup(root.ipcWindow.initialClass) : null);
    }


    function launchNewWindow() {
        for (let i = 0; i < root.actionItems.length; i++) {
            const item = root.actionItems[i];
            if (Actions.isNewWindowActionTitle(item.title)) {
                if (item.kind === "desktop") {
                    item.desktopAction.execute();
                } else if (item.kind === "gtk") {
                    root.activateGtkAction(item.gtkAction);
                }
                root.closePresentation();
                return;
            }
        }

        if (root.desktopEntry !== null) {
            root.desktopEntry.execute();
        } else if (root.ipcWindow?.class) {
            Hyprland.dispatch(`hl.dsp.exec_cmd("${root.ipcWindow.class.toLowerCase()}")`);
        }
        root.closePresentation();
    }

    function closeActiveWindow() {
        if (root.toplevel !== null) {
            root.toplevel.close();
        } else if (root.ipcWindow?.address) {
            Hyprland.dispatch(`hl.dsp.window.close({ address = "${root.ipcWindow.address}" })`);
        } else {
            Hyprland.dispatch("hl.dsp.window.close()");
        }
        root.closePresentation();
    }

    function forceQuitActiveWindow() {
        Hyprland.dispatch("hl.dsp.window.kill()");
        if (root.activePid > 0)
            backend.killProcess.exec(["kill", "-9", String(root.activePid)]);
        root.closePresentation();
    }

    function entryName(entry, appId) {
        return entry?.name?.length > 0 ? entry.name : Actions.friendlyName(appId);
    }

    function entryIcon(entry) {
        return entry?.icon?.length > 0 ? Quickshell.iconPath(entry.icon, true) : "";
    }






    function actionIconSource(actionIcon, resolveIconName) {
        const icon = String(actionIcon ?? "");
        if (icon.length > 0) {
            const source = resolveIconName ? Quickshell.iconPath(icon, true) : icon;
            if (source.length > 0)
                return source;
        }
        return "";
    }



    function requestIsCurrent(request) {
        if (request === null || root.actionRequest === null || !root.actionResolving)
            return false;

        const active = ToplevelManager.activeToplevel;
        return request.generation === root.actionGeneration
            && request.generation === root.actionRequest.generation
            && request.target !== null
            && request.target === root.actionRequest.target
            && Actions.toplevelAppId(request.target) === request.appId
            && (active === null || active === request.target)
            && Number(request.pid ?? 0) === Number(root.actionRequest.pid ?? 0)
            && String(request.address ?? "") === String(root.actionRequest.address ?? "");
    }

    function beginActionRequest(openWhenReady) {
        const target = ToplevelManager.activeToplevel;
        if (target === null)
            return;

        const appId = Actions.toplevelAppId(target);
        const desktopEntry = root.lookupDesktopEntry(appId);
        const liveIpcWindow = Hyprland.activeToplevel?.lastIpcObject;
        const expectedAddress = Actions.ipcMatchesApp(liveIpcWindow, appId)
            ? String(liveIpcWindow.address ?? "")
            : "";
        const request = Object.freeze({
            generation: ++root.actionGeneration,
            target: target,
            appId: appId,
            desktopEntry: desktopEntry,
            desktopActions: Actions.copyDesktopActions(desktopEntry?.actions),
            appName: root.entryName(desktopEntry, appId),
            iconSource: root.entryIcon(desktopEntry),
            title: String(target.title ?? root.entryName(desktopEntry, appId)),
            ipcWindow: Actions.snapshotIpcWindow(null),
            pid: 0,
            address: "",
            expectedAddress: expectedAddress
        });

        root.actionPresentation = null;
        root.presentationReusable = false;
        root.actionOpenRequested = openWhenReady;
        root.actionRequest = request;
        root.actionState = "resolving-window";
        backend.actionResolutionDeadline.restart();

        if (expectedAddress.length > 0 && Number(liveIpcWindow?.pid ?? 0) > 0) {
            root.finishWindowRequest(request, 0, JSON.stringify(liveIpcWindow));
            return;
        }

        root.pendingWindowRequest = request;
        root.startPendingWindowRequest();
    }

    function startPendingWindowRequest() {
        if (backend.activeWindowProcess.running || root.pendingWindowRequest === null)
            return;

        const request = root.pendingWindowRequest;
        root.pendingWindowRequest = null;
        if (!root.requestIsCurrent(request))
            return;

        backend.activeWindowProcess.request = request;
        backend.activeWindowProcess.exec(["hyprctl", "activewindow", "-j"]);
    }

    function finishWindowRequest(request, exitCode, output) {
        if (!root.requestIsCurrent(request))
            return;

        let window;
        try {
            window = JSON.parse(output);
        } catch (error) {
            root.finalizeActionRequest(request, [], true);
            return;
        }

        const ipcWindow = Actions.snapshotIpcWindow(window);
        if (exitCode !== 0
                || !Actions.ipcMatchesApp(ipcWindow, request.appId)
                || ipcWindow.pid <= 0
                || ipcWindow.address.length === 0) {
            root.finalizeActionRequest(request, [], true);
            return;
        }
        if (request.expectedAddress.length > 0 && ipcWindow.address !== request.expectedAddress)
            return;

        const resolved = Object.freeze({
            generation: request.generation,
            target: request.target,
            appId: request.appId,
            desktopEntry: request.desktopEntry,
            desktopActions: request.desktopActions,
            appName: request.appName,
            iconSource: request.iconSource,
            title: request.title,
            ipcWindow: ipcWindow,
            pid: ipcWindow.pid,
            address: ipcWindow.address,
            expectedAddress: request.expectedAddress
        });
        root.actionRequest = resolved;
        root.actionState = "resolving-gtk";
        if (root.hasNativeMenu) {
            root.finalizeActionRequest(resolved, [], false);
            return;
        }

        root.pendingGtkRequest = resolved;
        root.startPendingGtkRequest();
    }

    function startPendingGtkRequest() {
        if (backend.gtkListProcess.running || root.pendingGtkRequest === null)
            return;

        const request = root.pendingGtkRequest;
        root.pendingGtkRequest = null;
        if (!root.requestIsCurrent(request) || request.pid <= 0 || request.address.length === 0)
            return;

        backend.gtkListProcess.request = request;
        backend.gtkListProcess.exec(["quickshell-gtk-actions", "list", String(request.pid)]);
    }

    function finishGtkRequest(request, exitCode, output) {
        if (!root.requestIsCurrent(request)
                || request.pid !== root.actionRequest.pid
                || request.address !== root.actionRequest.address
                || request.target !== root.actionRequest.target)
            return;

        const actions = exitCode === 0 ? Actions.parseGtkActions(output) : null;
        if (actions === null) {
            root.finalizeActionRequest(request, [], true);
            return;
        }

        if (actions.length === 0
                && backend.qtMenuProbeProcess.running
                && backend.qtMenuProbeProcess.probedPid === request.pid) {
            root.deferredGtkResult = Object.freeze({
                request: request,
                actions: actions
            });
            return;
        }

        root.finalizeActionRequest(request, actions, false);
    }

    function finishDeferredGtkRequest() {
        const result = root.deferredGtkResult;
        root.deferredGtkResult = null;
        if (result !== null && root.requestIsCurrent(result.request))
            root.finalizeActionRequest(result.request, result.actions, false);
    }

    function finalizeActionRequest(request, gtkActions, unavailable) {
        if (!root.requestIsCurrent(request))
            return;

        backend.actionResolutionDeadline.stop();
        const presentation = Object.freeze({
            generation: request.generation,
            target: request.target,
            appId: request.appId,
            desktopEntry: request.desktopEntry,
            appName: request.appName,
            iconSource: request.iconSource,
            title: request.title,
            ipcWindow: request.ipcWindow,
            pid: request.pid,
            address: request.address,
            actionItems: Actions.combineActions(request.desktopActions, gtkActions),
            unavailable: unavailable
        });

        root.actionRequest = null;
        root.actionPresentation = presentation;
        root.presentationReusable = true;
        root.actionState = root.actionOpenRequested ? "open" : "ready";
        root.actionOpenRequested = false;
    }

    function cancelResolution() {
        backend.actionResolutionDeadline.stop();
        root.actionGeneration++;
        root.actionRequest = null;
        root.actionPresentation = null;
        root.pendingWindowRequest = null;
        root.pendingGtkRequest = null;
        root.deferredGtkResult = null;
        root.actionOpenRequested = false;
        root.presentationReusable = false;
        root.actionState = "idle";
    }

    function closePresentation() {
        if (root.actionResolving) {
            root.cancelResolution();
        } else if (root.actionsOpen) {
            root.actionState = "closing";
        }
    }

    function invalidateActionTarget() {
        if (root.actionState === "idle")
            return;

        backend.actionResolutionDeadline.stop();
        root.actionGeneration++;
        root.actionRequest = null;
        root.pendingWindowRequest = null;
        root.pendingGtkRequest = null;
        root.deferredGtkResult = null;
        root.actionOpenRequested = false;
        root.presentationReusable = false;
        if (root.actionPresentation !== null && (root.actionsOpen || root.actionState === "closing")) {
            root.actionState = "closing";
        } else {
            root.actionPresentation = null;
            root.actionState = "idle";
        }
    }

    function finishClosing() {
        if (root.actionState !== "closing")
            return;

        if (root.presentationReusable) {
            root.actionState = "ready";
        } else {
            root.actionPresentation = null;
            root.actionState = "idle";
            Qt.callLater(() => root.prefetchActions());
        }
    }

    function presentationCanReopen() {
        const presentation = root.actionPresentation;
        const active = ToplevelManager.activeToplevel;
        return root.presentationReusable
            && presentation !== null
            && presentation.target !== null
            && Actions.toplevelAppId(presentation.target) === presentation.appId
            && (active === null || active === presentation.target);
    }

    function toggleActions() {
        if (root.actionResolving) {
            root.actionOpenRequested = true;
        } else if (root.actionsOpen) {
            root.closePresentation();
        } else if (root.actionState === "closing") {
            if (root.presentationCanReopen())
                root.actionState = "open";
        } else if (root.actionState === "ready") {
            if (root.presentationCanReopen()) {
                root.actionState = "open";
            } else {
                root.invalidateActionTarget();
                Qt.callLater(() => root.beginActionRequest(true));
            }
        } else {
            root.beginActionRequest(true);
        }
    }

    function activateGtkAction(action) {
        const presentation = root.actionPresentation;
        if (presentation === null)
            return;

        root.pendingActivationRequest = Object.freeze({
            generation: presentation.generation,
            target: presentation.target,
            appId: presentation.appId,
            pid: presentation.pid,
            address: presentation.address,
            service: action.service,
            path: action.path,
            action: action.action
        });
        root.startPendingActivationRequest();
        root.closePresentation();
    }

    function startPendingActivationRequest() {
        if (backend.gtkActivateProcess.running || root.pendingActivationRequest === null)
            return;

        const request = root.pendingActivationRequest;
        root.pendingActivationRequest = null;
        backend.gtkActivateProcess.request = request;
        backend.gtkActivateProcess.exec([
            "quickshell-gtk-actions",
            "activate",
            request.service,
            request.path,
            request.action
        ]);
    }

    AppMenuBackend {
        id: backend
        owner: root
    }

    Row {
        id: menuRow

        height: parent.height
        spacing: Theme.gap * 2

        Item {
            id: identityButton

            width: Math.min(root.maxWidth, 148, identityRow.implicitWidth)
            height: parent.height
            clip: false

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: -Theme.gap * 2
                    rightMargin: -Theme.gap * 2
                }
                height: 28
                color: identityMouse.containsMouse || triggerBridgeHover.hovered
                    ? Theme.panelSurfaceHover
                    : "transparent"
                radius: Theme.radius
            }

            Row {
                id: identityRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.gap * 2

                IconImage {
                    visible: root.iconSource.length > 0 && identityButton.width >= 16
                    width: 16
                    height: 16
                    source: root.iconSource
                }

                Text {
                    width: Math.max(0, Math.min(116, implicitWidth, identityButton.width - (root.iconSource.length > 0 ? 16 + identityRow.spacing : 0)))
                    color: Theme.red
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.weight: Theme.emphasisWeight
                    text: root.appName
                }

            }

            MouseArea {
                id: identityMouse

                anchors.fill: parent
                enabled: root.toplevel !== null
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.toggleActions()
            }
        }
    }

    PanelWindow {
        id: actionsWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.actionsOpen || root.actionState === "closing" || actionsPanel.progress > 0
        implicitWidth: actionsPanel.length
        implicitHeight: Theme.popupGap + actionsPanel.depth
        mask: Region {
            Region {
                item: triggerBridge
            }

            Region {
                item: actionsPanel
            }
        }

        WlrLayershell.namespace: "quickshell:appMenuActions"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.actionsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
        }

        margins {
            top: Theme.barHeight
            left: Math.max(Theme.gap * 2, root.popupLeftMargin)
        }

        Item {
            id: actionsHost

            anchors.fill: parent

            Item {
                id: triggerBridge

                width: parent.width
                height: Theme.popupGap

                HoverHandler {
                    id: triggerBridgeHover
                }
            }

            Frame.PulloutPanel {
                id: actionsPanel

                corner: "topLeft"
                requestedOpen: root.actionsOpen
                autoClose: false
                clickDismiss: true
                activatorMouseArea: identityMouse
                onDismissRequested: root.closePresentation()
                length: 280
                depth: Math.min(root.maxPopupDepth,
                    actionsContent.implicitHeight
                        + (detailsSection.visible ? detailsContent.implicitHeight + Theme.panelItemGap : 0)
                        + Theme.panelPadding * 2)
                duration: 0
                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                onProgressChanged: {
                    if (root.actionState === "closing" && actionsPanel.progress <= 0)
                        root.finishClosing();
                }

                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: Theme.popupGap
                }

                FocusScope {
                    id: actionsFocus

                    anchors.fill: parent
                    focus: root.actionsOpen

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closePresentation();
                            event.accepted = true;
                        }
                    }

                    Flickable {
                        id: actionsScroll

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            bottom: detailsSection.top
                            topMargin: Theme.panelPadding
                            leftMargin: Theme.panelPadding
                            rightMargin: Theme.panelPadding
                            bottomMargin: detailsSection.visible ? Theme.panelItemGap : 0
                        }
                        visible: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: actionsContent.implicitHeight
                        interactive: contentHeight > height

                        ColumnLayout {
                            id: actionsContent

                            width: actionsScroll.width
                            spacing: Theme.panelItemGap

                            Frame.PanelGroupLabel {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot && (root.canLaunchNewWindow || root.specificActionItems.length > 0)
                                title: "Actions"
                            }

                            Frame.PanelActionRow {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot && root.canLaunchNewWindow
                                icon: ""
                                label: "New Window"
                                onClicked: root.launchNewWindow()
                            }

                            Repeater {
                                model: root.specificActionItems

                                Frame.PanelActionRow {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    visible: nativeMenuView.atRoot
                                    icon: Actions.actionGlyph(modelData.title)
                                    iconSource: root.actionIconSource(modelData.desktopAction?.icon, true)
                                    label: modelData.title
                                    showTrailing: false
                                    onClicked: {
                                        if (modelData.kind === "desktop") {
                                            modelData.desktopAction.execute();
                                            root.closePresentation();
                                        } else {
                                            root.activateGtkAction(modelData.gtkAction);
                                        }
                                    }
                                }
                            }

                            Frame.PanelDivider {
                                Layout.fillWidth: true
                                fullWidth: true
                                visible: nativeMenuView.atRoot && root.hasNativeMenu
                            }

                            Frame.PanelGroupLabel {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot && root.hasNativeMenu
                                title: "Menu"
                            }

                            Frame.PanelMenuView {
                                id: nativeMenuView

                                visible: root.hasNativeMenu
                                Layout.fillWidth: true
                                menu: root.nativeMenu
                                onActivated: root.closePresentation()
                            }

                            Frame.PanelDivider {
                                Layout.fillWidth: true
                                fullWidth: true
                                visible: nativeMenuView.atRoot
                            }

                            Frame.PanelGroupLabel {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot
                                title: "Application"
                            }

                            Frame.PanelActionRow {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot
                                icon: "󰅖"
                                label: "Close Window"
                                onClicked: root.closeActiveWindow()
                            }

                            Frame.PanelActionRow {
                                Layout.fillWidth: true
                                visible: nativeMenuView.atRoot
                                icon: "󰅚"
                                label: "Force Quit"
                                accentColor: Theme.red
                                onClicked: root.forceQuitActiveWindow()
                            }

                        }
                    }

                    Item {
                        id: detailsSection

                        visible: nativeMenuView.atRoot
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: Theme.panelPadding
                            rightMargin: Theme.panelPadding
                            bottomMargin: Theme.panelPadding
                        }
                        height: visible ? detailsContent.implicitHeight : 0

                        ColumnLayout {
                            id: detailsContent

                            width: parent.width
                            spacing: Theme.gap

                            Frame.PanelDivider {
                                Layout.fillWidth: true
                                fullWidth: true
                            }

                            Item {
                                Layout.preferredHeight: Theme.gap
                            }

                            WindowDetails {
                                Layout.fillWidth: true
                                windowTitle: root.actionPresentation?.title ?? root.appName
                                pid: root.activePid > 0 ? String(root.activePid) : "Unknown"
                                className: root.ipcWindow.class?.length > 0 ? root.ipcWindow.class : root.appId
                                workspace: root.ipcWindow.workspace?.name?.length > 0
                                    ? root.ipcWindow.workspace.name
                                    : root.ipcWindow.workspace?.id > 0
                                        ? String(root.ipcWindow.workspace.id)
                                        : "Unknown"
                            }
                        }
                    }

                    Frame.PanelScrollIndicator {
                        anchors {
                            top: actionsScroll.top
                            right: parent.right
                            bottom: actionsScroll.bottom
                            rightMargin: Theme.gap
                        }
                        flickable: actionsScroll
                    }
                }
            }
        }
    }
}
