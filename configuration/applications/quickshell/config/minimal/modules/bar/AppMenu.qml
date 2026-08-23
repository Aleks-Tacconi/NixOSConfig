pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Hyprland
import Quickshell.Io
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
    property bool nativeMenuOpen: false
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
        if (root.ipcMatchesApp(liveWindow, root.appId))
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
        ?? root.toplevelAppId(root.toplevel)
    readonly property var desktopEntry: root.actionPresentation?.desktopEntry
        ?? root.actionRequest?.desktopEntry
        ?? root.lookupDesktopEntry(root.appId)
    readonly property var actionItems: root.actionPresentation?.actionItems ?? []
    readonly property bool actionInteractionHovered: identityMouse.containsMouse
        || triggerBridgeHover.hovered
        || actionsPanel.panelHovered
        || root.nativeMenuOpen
    readonly property string appName: root.actionPresentation?.appName
        ?? root.actionRequest?.appName
        ?? root.entryName(root.desktopEntry, root.appId)
    readonly property string iconSource: root.actionPresentation?.iconSource
        ?? root.actionRequest?.iconSource
        ?? root.entryIcon(root.desktopEntry)

    visible: ShellConfig.Config.appMenu.enable && root.toplevel !== null
    width: visible ? Math.min(root.maxWidth, menuRow.implicitWidth) : 0
    height: Theme.barHeight
    clip: false

    Component.onCompleted: {
        root.queueNativeMenuProbe();
        Qt.callLater(() => root.prefetchActions());
    }
    onActivePidChanged: root.queueNativeMenuProbe()

    onActionStateChanged: {
        actionHoverClose.stop();
        if (root.actionsOpen && !root.actionInteractionHovered)
            actionHoverClose.restart();
    }
    onActionInteractionHoveredChanged: {
        if (root.actionInteractionHovered) {
            actionHoverClose.stop();
        } else if (root.actionsOpen) {
            actionHoverClose.restart();
        }
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
            if (!root.nativeMenuOpen
                    && active !== null && root.actionTarget !== null && active !== root.actionTarget)
                root.invalidateActionTarget();

            Qt.callLater(() => root.prefetchActions());
        }
    }

    function prefetchActions() {
        const active = ToplevelManager.activeToplevel;
        if (root.nativeMenuOpen || active === null || root.actionsOpen || root.actionState === "closing")
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
        if (qtMenuProbeProcess.running || root.pendingNativeProbePid <= 0)
            return;

        const pid = root.pendingNativeProbePid;
        root.pendingNativeProbePid = 0;
        if (pid !== root.activePid)
            return;

        qtMenuProbeProcess.probedPid = pid;
        qtMenuProbeProcess.exec(["quickshell-qt-menu", String(pid)]);
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

    function snapshotIpcWindow(window) {
        return Object.freeze({
            address: String(window?.address ?? ""),
            pid: Number(window?.pid ?? 0),
            class: String(window?.class ?? ""),
            title: String(window?.title ?? ""),
            workspace: Object.freeze({
                id: Number(window?.workspace?.id ?? 0),
                name: String(window?.workspace?.name ?? "")
            })
        });
    }

    function normalizedAppId(value) {
        return String(value ?? "")
            .toLowerCase()
            .replace(/\.desktop$/, "")
            .replace(/[^a-z0-9]+/g, "");
    }

    function ipcMatchesApp(window, appId) {
        if (Number(window?.pid ?? 0) <= 0)
            return false;

        const windowClass = root.normalizedAppId(window?.class);
        const applicationId = root.normalizedAppId(appId);
        return windowClass.length > 0 && applicationId.length > 0
            && (windowClass === applicationId
                || windowClass.endsWith(applicationId)
                || applicationId.endsWith(windowClass));
    }

    function toplevelAppId(target) {
        const appId = String(target?.appId ?? "");
        return appId.length > 0 ? appId : "Application";
    }

    function lookupDesktopEntry(appId) {
        return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? null;
    }

    function entryName(entry, appId) {
        return entry?.name?.length > 0 ? entry.name : root.friendlyName(appId);
    }

    function entryIcon(entry) {
        return entry?.icon?.length > 0 ? Quickshell.iconPath(entry.icon, true) : "";
    }

    function copyDesktopActions(actions) {
        const copy = [];
        for (let index = 0; index < (actions?.length ?? 0); index++) {
            copy.push(actions[index]);
        }
        return Object.freeze(copy);
    }

    function friendlyName(appId) {
        const shortName = appId.split(".").pop() || "Application";
        const spaced = shortName
            .replace(/[-_]+/g, " ")
            .replace(/([a-z0-9])([A-Z])/g, "$1 $2");

        return spaced.replace(/\b\w/g, letter => letter.toUpperCase());
    }

    function actionKey(value) {
        return String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "");
    }

    function actionKeys(title, actionId) {
        const shortId = String(actionId ?? "").split(".").pop();
        return [root.actionKey(title), root.actionKey(shortId)].filter(key => key.length > 0);
    }

    function combineActions(desktopActions, gtkActions) {
        const combined = [];
        const seen = [];

        for (let index = 0; index < desktopActions.length; index++) {
            const desktopAction = desktopActions[index];
            const title = String(desktopAction.name ?? "").trim();
            if (title.length === 0)
                continue;

            const keys = root.actionKeys(title, "");
            combined.push(Object.freeze({
                kind: "desktop",
                title: title,
                desktopAction: desktopAction
            }));
            seen.push(...keys);
        }

        for (const gtkAction of gtkActions) {
            const keys = root.actionKeys(gtkAction.title, gtkAction.action);
            if (keys.some(key => seen.includes(key)))
                continue;

            combined.push(Object.freeze({
                kind: "gtk",
                title: gtkAction.title,
                gtkAction: gtkAction
            }));
            seen.push(...keys);
        }

        return Object.freeze(combined);
    }

    function parseGtkActions(output) {
        try {
            const actions = JSON.parse(output);
            if (!Array.isArray(actions))
                return null;

            const parsed = [];
            for (const action of actions) {
                if (action === null
                        || typeof action.service !== "string" || action.service.length === 0
                        || typeof action.path !== "string" || !action.path.startsWith("/")
                        || typeof action.action !== "string" || action.action.length === 0
                        || typeof action.title !== "string" || action.title.length === 0)
                    return null;

                parsed.push(Object.freeze({
                    service: action.service,
                    path: action.path,
                    action: action.action,
                    title: action.title
                }));
            }
            return Object.freeze(parsed);
        } catch (error) {
            return null;
        }
    }

    function requestIsCurrent(request) {
        if (request === null || root.actionRequest === null || !root.actionResolving)
            return false;

        const active = ToplevelManager.activeToplevel;
        return request.generation === root.actionGeneration
            && request.generation === root.actionRequest.generation
            && request.target !== null
            && request.target === root.actionRequest.target
            && root.toplevelAppId(request.target) === request.appId
            && (active === null || active === request.target)
            && Number(request.pid ?? 0) === Number(root.actionRequest.pid ?? 0)
            && String(request.address ?? "") === String(root.actionRequest.address ?? "");
    }

    function beginActionRequest(openWhenReady) {
        const target = ToplevelManager.activeToplevel;
        if (target === null)
            return;

        const appId = root.toplevelAppId(target);
        const desktopEntry = root.lookupDesktopEntry(appId);
        const liveIpcWindow = Hyprland.activeToplevel?.lastIpcObject;
        const expectedAddress = root.ipcMatchesApp(liveIpcWindow, appId)
            ? String(liveIpcWindow.address ?? "")
            : "";
        const request = Object.freeze({
            generation: ++root.actionGeneration,
            target: target,
            appId: appId,
            desktopEntry: desktopEntry,
            desktopActions: root.copyDesktopActions(desktopEntry?.actions),
            appName: root.entryName(desktopEntry, appId),
            iconSource: root.entryIcon(desktopEntry),
            title: String(target.title ?? root.entryName(desktopEntry, appId)),
            ipcWindow: root.snapshotIpcWindow(null),
            pid: 0,
            address: "",
            expectedAddress: expectedAddress
        });

        root.actionPresentation = null;
        root.presentationReusable = false;
        root.actionOpenRequested = openWhenReady;
        root.actionRequest = request;
        root.actionState = "resolving-window";
        actionResolutionDeadline.restart();

        if (expectedAddress.length > 0 && Number(liveIpcWindow?.pid ?? 0) > 0) {
            root.finishWindowRequest(request, 0, JSON.stringify(liveIpcWindow));
            return;
        }

        root.pendingWindowRequest = request;
        root.startPendingWindowRequest();
    }

    function startPendingWindowRequest() {
        if (activeWindowProcess.running || root.pendingWindowRequest === null)
            return;

        const request = root.pendingWindowRequest;
        root.pendingWindowRequest = null;
        if (!root.requestIsCurrent(request))
            return;

        activeWindowProcess.request = request;
        activeWindowProcess.exec(["hyprctl", "activewindow", "-j"]);
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

        const ipcWindow = root.snapshotIpcWindow(window);
        if (exitCode !== 0
                || !root.ipcMatchesApp(ipcWindow, request.appId)
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
        if (gtkListProcess.running || root.pendingGtkRequest === null)
            return;

        const request = root.pendingGtkRequest;
        root.pendingGtkRequest = null;
        if (!root.requestIsCurrent(request) || request.pid <= 0 || request.address.length === 0)
            return;

        gtkListProcess.request = request;
        gtkListProcess.exec(["quickshell-gtk-actions", "list", String(request.pid)]);
    }

    function finishGtkRequest(request, exitCode, output) {
        if (!root.requestIsCurrent(request)
                || request.pid !== root.actionRequest.pid
                || request.address !== root.actionRequest.address
                || request.target !== root.actionRequest.target)
            return;

        const actions = exitCode === 0 ? root.parseGtkActions(output) : null;
        if (actions === null) {
            root.finalizeActionRequest(request, [], true);
            return;
        }

        if (actions.length === 0
                && qtMenuProbeProcess.running
                && qtMenuProbeProcess.probedPid === request.pid) {
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

        actionResolutionDeadline.stop();
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
            actionItems: root.combineActions(request.desktopActions, gtkActions),
            unavailable: unavailable
        });

        root.actionRequest = null;
        root.actionPresentation = presentation;
        root.presentationReusable = true;
        root.actionState = root.actionOpenRequested ? "open" : "ready";
        root.actionOpenRequested = false;
    }

    function cancelResolution() {
        actionResolutionDeadline.stop();
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
        actionHoverClose.stop();
        if (root.actionResolving) {
            root.cancelResolution();
        } else if (root.actionsOpen) {
            root.actionState = "closing";
        }
    }

    function invalidateActionTarget() {
        if (root.actionState === "idle")
            return;

        actionResolutionDeadline.stop();
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
            && root.toplevelAppId(presentation.target) === presentation.appId
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
        if (gtkActivateProcess.running || root.pendingActivationRequest === null)
            return;

        const request = root.pendingActivationRequest;
        root.pendingActivationRequest = null;
        gtkActivateProcess.request = request;
        gtkActivateProcess.exec([
            "quickshell-gtk-actions",
            "activate",
            request.service,
            request.path,
            request.action
        ]);
    }

    Process {
        id: activeWindowProcess

        property var request: null

        stdout: StdioCollector {
            id: activeWindowOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.finishWindowRequest(activeWindowProcess.request, exitCode, activeWindowOutput.text);
            activeWindowProcess.request = null;
            Qt.callLater(() => root.startPendingWindowRequest());
        }
    }

    Process {
        id: gtkListProcess

        property var request: null

        stdout: StdioCollector {
            id: gtkListOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.finishGtkRequest(gtkListProcess.request, exitCode, gtkListOutput.text);
            gtkListProcess.request = null;
            Qt.callLater(() => root.startPendingGtkRequest());
        }
    }

    Process {
        id: gtkActivateProcess

        property var request: null

        onExited: {
            gtkActivateProcess.request = null;
            Qt.callLater(() => root.startPendingActivationRequest());
        }
    }

    Process {
        id: qtMenuProbeProcess

        property int probedPid: 0

        stdout: StdioCollector {
            id: qtMenuProbeOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.finishNativeMenuProbe(qtMenuProbeProcess.probedPid, exitCode, qtMenuProbeOutput.text);
            qtMenuProbeProcess.probedPid = 0;
            Qt.callLater(() => root.finishDeferredGtkRequest());
            Qt.callLater(() => root.startPendingNativeMenuProbe());
        }
    }

    Timer {
        id: actionResolutionDeadline

        interval: 2000
        onTriggered: {
            const request = root.actionRequest;
            if (request !== null && root.actionResolving)
                root.finalizeActionRequest(request, [], true);
        }
    }

    Timer {
        id: actionHoverClose

        interval: 200
        onTriggered: {
            if (root.actionsOpen && !root.actionInteractionHovered)
                root.closePresentation();
        }
    }

    QsMenuOpener {
        id: nativeRoot

        menu: root.nativeMenu
    }

    Row {
        id: menuRow

        height: parent.height
        spacing: Theme.gap * 2

        Item {
            id: identityButton

            width: Math.min(148, identityRow.implicitWidth)
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
                    visible: root.iconSource.length > 0
                    width: 16
                    height: 16
                    source: root.iconSource
                }

                Text {
                    width: Math.min(116, implicitWidth)
                    color: Theme.red
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
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
                dismissOnExit: false
                length: 280
                depth: Math.min(root.maxPopupDepth, actionsContent.implicitHeight + Theme.panelPadding * 2)
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
                            fill: parent
                            topMargin: Theme.panelPadding
                            bottomMargin: Theme.panelPadding
                            leftMargin: Theme.panelPadding + Theme.gap * 2
                            rightMargin: Theme.panelPadding
                        }
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: actionsContent.implicitHeight
                        interactive: contentHeight > height

                        ColumnLayout {
                            id: actionsContent

                            width: actionsScroll.width
                        spacing: Theme.panelItemGap

                        Frame.PanelSectionHeader {
                            Layout.fillWidth: true
                            title: root.appName
                            showMarker: false
                        }

                        Frame.PanelSectionHeader {
                            Layout.fillWidth: true
                            title: "Details"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Theme.panelItemGap
                            rowSpacing: Theme.gap

                            Text {
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: "Title"
                            }

                            Text {
                                Layout.fillWidth: true
                                color: Theme.fg
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: root.actionPresentation?.title ?? root.appName
                            }

                            Text {
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: "PID"
                            }

                            Text {
                                Layout.fillWidth: true
                                color: Theme.fg
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: root.activePid > 0 ? String(root.activePid) : "Unknown"
                            }

                            Text {
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: "Class"
                            }

                            Text {
                                Layout.fillWidth: true
                                color: Theme.fg
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: root.ipcWindow.class?.length > 0 ? root.ipcWindow.class : root.appId
                            }

                            Text {
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: "Workspace"
                            }

                            Text {
                                Layout.fillWidth: true
                                color: Theme.fg
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                text: root.ipcWindow.workspace?.name?.length > 0
                                    ? root.ipcWindow.workspace.name
                                    : root.ipcWindow.workspace?.id > 0
                                        ? String(root.ipcWindow.workspace.id)
                                        : "Unknown"
                            }
                        }

                        Frame.PanelSectionHeader {
                            Layout.fillWidth: true
                            title: "Actions"
                        }

                        Repeater {
                            model: root.actionItems

                            Frame.PanelActionRow {
                                required property var modelData

                                Layout.fillWidth: true
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

                        Repeater {
                            model: root.hasNativeMenu ? nativeRoot.children : null

                            Frame.PanelActionRow {
                                id: nativeActionRow

                                required property var modelData

                                Layout.fillWidth: true
                                visible: !modelData.isSeparator && modelData.text.length > 0
                                enabled: modelData.enabled
                                label: modelData.text
                                showTrailing: modelData.hasChildren
                                onClicked: {
                                    const point = mapToItem(null, width, 0);
                                    root.nativeMenuOpen = true;
                                    modelData.display(actionsWindow, point.x, point.y);
                                }

                                Connections {
                                    target: nativeActionRow.modelData
                                    ignoreUnknownSignals: true

                                    function onOpened() {
                                        root.nativeMenuOpen = true;
                                    }

                                    function onClosed() {
                                        root.nativeMenuOpen = false;
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.hasNativeMenu
                                && root.actionPresentation !== null
                                && (root.actionPresentation.unavailable || root.actionItems.length === 0)
                            color: Theme.muted
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                            text: root.actionPresentation?.unavailable
                                ? "Actions unavailable"
                                : "No actions available"
                        }
                        }
                    }
                }
            }
        }
    }
}
