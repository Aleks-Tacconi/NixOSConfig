pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../.." as ShellConfig
import "../dock/tray-apps.js" as TrayApps
import "app-menu-actions.js" as Actions

/**
 * Shared service resolving active window metadata, native menus, and GTK actions across monitors.
 */
Scope {
    id: root

    property int actionGeneration: 0
    property var actionRequest: null
    property var resolvedIpc: null
    property var resolvedGtk: null

    readonly property bool actionResolving: root.actionRequest !== null
    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string appId: Actions.toplevelAppId(root.toplevel)
    readonly property var ipcWindow: {
        if (root.resolvedIpc !== null && root.resolvedIpc.target === root.toplevel)
            return root.resolvedIpc.window;
        const liveWindow = Hyprland.activeToplevel?.lastIpcObject;
        return Actions.ipcMatchesApp(liveWindow, root.appId)
            ? Actions.snapshotIpcWindow(liveWindow)
            : Actions.snapshotIpcWindow(null);
    }
    readonly property int activePid: Number(root.ipcWindow.pid ?? 0)
    readonly property var registrarMenu: {
        const revision = AppMenuRegistrar.revision;
        return ShellConfig.Config.appMenu.nativeMenus && root.activePid > 0 && revision >= 0
            ? AppMenuRegistrar.menuForPid(root.activePid)
            : null;
    }
    readonly property var nativeMenu: {
        if (root.registrarMenu !== null)
            return root.registrarMenu;
        for (const item of SystemTray.items.values) {
            if (!item.hasMenu || !item.menu)
                continue;
            const entry = TrayApps.desktopEntryForTray(item, DesktopEntries.applications.values);
            if (TrayApps.matchesGroup({ item: item, desktopEntry: entry }, root.appId, root.desktopEntry))
                return item.menu;
        }
        return null;
    }
    readonly property bool hasNativeMenu: root.nativeMenu !== null
    readonly property var desktopEntry: DesktopEntries.byId(root.appId)
        ?? DesktopEntries.heuristicLookup(root.appId)
        ?? (root.ipcWindow?.class ? DesktopEntries.heuristicLookup(root.ipcWindow.class) : null)
        ?? (root.ipcWindow?.initialClass ? DesktopEntries.heuristicLookup(root.ipcWindow.initialClass) : null)
    readonly property var gtkActions: root.resolvedGtk !== null
        && root.resolvedGtk.target === root.toplevel
        && root.resolvedGtk.pid === root.activePid
        ? root.resolvedGtk.actions
        : []
    readonly property var actionItems: root.toplevel !== null
        ? Actions.combineActions(Actions.copyDesktopActions(root.desktopEntry?.actions), root.gtkActions)
        : []
    readonly property var specificActionItems: root.actionItems.filter(item => !Actions.isNewWindowActionTitle(item.title))
    readonly property bool hasExplicitNewWindowAction: root.actionItems.some(item => Actions.isNewWindowActionTitle(item.title))
    readonly property bool canLaunchNewWindow: root.desktopEntry !== null
        || (root.ipcWindow?.class?.length ?? 0) > 0
        || root.hasExplicitNewWindowAction
    readonly property string appName: root.desktopEntry?.name?.length > 0 ? root.desktopEntry.name : Actions.friendlyName(root.appId)
    readonly property string iconSource: root.desktopEntry?.icon?.length > 0 ? Quickshell.iconPath(root.desktopEntry.icon, true) : ""
    readonly property string windowTitle: String(root.toplevel?.title ?? root.appName)
    readonly property string className: root.ipcWindow.class?.length > 0 ? root.ipcWindow.class : root.appId
    readonly property string workspace: root.ipcWindow.workspace?.name?.length > 0
        ? root.ipcWindow.workspace.name
        : (root.ipcWindow.workspace?.id ?? 0) > 0 ? String(root.ipcWindow.workspace.id) : "Unknown"

    Component.onCompleted: {
        root.queueNativeMenuProbe();
        Qt.callLater(() => root.refreshActiveWindow());
    }
    onActivePidChanged: root.queueNativeMenuProbe()

    Connections {
        target: ToplevelManager

        function onActiveToplevelChanged() {
            Qt.callLater(() => root.refreshActiveWindow());
        }
    }

    AppMenuBackend {
        id: backend
        owner: root
    }

    function actionIconSource(actionIcon, resolveIconName) {
        const icon = String(actionIcon ?? "");
        return icon.length === 0 ? "" : (resolveIconName ? Quickshell.iconPath(icon, true) : icon);
    }

    function queueNativeMenuProbe() {
        if (ShellConfig.Config.appMenu.nativeMenus && root.activePid > 0 && root.registrarMenu === null)
            backend.probeNativeMenu(root.activePid);
    }

    function finishNativeMenuProbe(pid, exitCode, output) {
        if (exitCode !== 0 || pid !== root.activePid)
            return;
        try {
            const ep = JSON.parse(output);
            if (typeof ep?.service === "string" && ep.service.startsWith(":") && typeof ep?.path === "string" && ep.path.startsWith("/"))
                AppMenuRegistrar.registerMenuForPid(pid, ep.service, ep.path);
        } catch (error) {
            return;
        }
    }

    function ensureResolved() {
        if (root.toplevel !== null && !root.actionResolving && (root.resolvedGtk === null || root.resolvedGtk.target !== root.toplevel))
            root.refreshActiveWindow();
    }

    function refreshActiveWindow() {
        const target = ToplevelManager.activeToplevel;
        backend.resetQueues();
        if (target === null) {
            root.actionGeneration++;
            root.actionRequest = null;
            root.resolvedIpc = null;
            root.resolvedGtk = null;
            return;
        }

        const appId = Actions.toplevelAppId(target);
        const liveIpc = Hyprland.activeToplevel?.lastIpcObject;
        const expectedAddress = Actions.ipcMatchesApp(liveIpc, appId) ? String(liveIpc.address ?? "") : "";
        const request = Object.freeze({
            generation: ++root.actionGeneration,
            target: target,
            appId: appId,
            pid: 0,
            address: "",
            expectedAddress: expectedAddress
        });
        root.actionRequest = request;
        backend.startDeadline();
        if (expectedAddress.length > 0 && Number(liveIpc?.pid ?? 0) > 0)
            root.finishWindowRequest(request, 0, JSON.stringify(liveIpc));
        else
            backend.requestWindow(request);
    }

    function requestIsCurrent(request) {
        const active = ToplevelManager.activeToplevel;
        return request !== null && root.actionRequest !== null
            && request.generation === root.actionGeneration
            && request.generation === root.actionRequest.generation
            && request.target !== null && request.target === root.actionRequest.target
            && Actions.toplevelAppId(request.target) === request.appId
            && (active === null || active === request.target);
    }

    function finishWindowRequest(request, exitCode, output) {
        if (!root.requestIsCurrent(request))
            return;
        let parsed = null;
        try {
            parsed = JSON.parse(output);
        } catch (error) {
            root.finalizeActionRequest(request, [], true);
            return;
        }
        const ipcWindow = Actions.snapshotIpcWindow(parsed);
        if (exitCode !== 0 || !Actions.ipcMatchesApp(ipcWindow, request.appId) || ipcWindow.pid <= 0 || ipcWindow.address.length === 0) {
            root.finalizeActionRequest(request, [], true);
            return;
        }
        if (request.expectedAddress.length > 0 && ipcWindow.address !== request.expectedAddress)
            return;

        root.resolvedIpc = Object.freeze({ target: request.target, window: ipcWindow });
        const resolved = Object.freeze(Object.assign({}, request, { pid: ipcWindow.pid, address: ipcWindow.address }));
        root.actionRequest = resolved;
        if (root.registrarMenu !== null)
            root.finalizeActionRequest(resolved, [], false);
        else
            backend.requestGtk(resolved);
    }

    function finishGtkRequest(request, exitCode, output) {
        if (!root.requestIsCurrent(request) || request.pid !== root.actionRequest.pid)
            return;
        const actions = exitCode === 0 ? Actions.parseGtkActions(output) : null;
        root.finalizeActionRequest(request, actions ?? [], actions === null);
    }

    function finalizeActionRequest(request, gtkActions, unavailable) {
        if (!root.requestIsCurrent(request))
            return;
        backend.stopDeadline();
        root.actionRequest = null;
        root.resolvedGtk = Object.freeze({ target: request.target, pid: request.pid, actions: gtkActions, unavailable: unavailable });
    }

    function launchNewWindow() {
        const explicit = root.actionItems.find(item => Actions.isNewWindowActionTitle(item.title));
        if (explicit) {
            if (explicit.kind === "desktop")
                explicit.desktopAction.execute();
            else if (explicit.kind === "gtk")
                root.activateGtkAction(explicit.gtkAction);
            return;
        }
        if (root.desktopEntry !== null)
            root.desktopEntry.execute();
        else if (root.ipcWindow?.class)
            Hyprland.dispatch(`hl.dsp.exec_cmd("${root.ipcWindow.class.toLowerCase()}")`);
    }

    function closeActiveWindow() {
        if (root.toplevel !== null)
            root.toplevel.close();
        else if (root.ipcWindow?.address)
            Hyprland.dispatch(`hl.dsp.window.close({ address = "${root.ipcWindow.address}" })`);
        else
            Hyprland.dispatch("hl.dsp.window.close()");
    }

    function forceQuitActiveWindow() {
        Hyprland.dispatch("hl.dsp.window.kill()");
        backend.killPid(root.activePid);
    }

    function activateGtkAction(action) {
        backend.activateGtk(action.service, action.path, action.action);
    }
}
