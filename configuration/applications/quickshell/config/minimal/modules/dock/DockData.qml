pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "tray-apps.js" as TrayApps

/**
 * Groups open windows, pinned apps, and exposed menus for the dock.
 */
Scope {
    id: root

    property var gtkActionsByPid: ({})
    property int pendingGtkPid: 0
    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string stateHome: {
        const configured = Quickshell.env("XDG_STATE_HOME") ?? "";
        return configured.length > 0 ? configured : `${Quickshell.env("HOME") ?? ""}/.local/state`;
    }
    readonly property string pinsPath: `${root.stateHome}/quickshell/dock-pins.json`
    readonly property var appGroups: {
        const groups = new Map();
        const pinnedApps = dockPins.pinnedApps ?? [];

        for (const appId of pinnedApps) {
            const key = root.normalizedAppId(appId);
            if (!groups.has(key))
                groups.set(key, { appId, pinned: true, toplevels: [] });
        }

        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = root.appIdForToplevel(toplevel);
            const key = root.normalizedAppId(appId);
            if (!groups.has(key))
                groups.set(key, { appId, pinned: false, toplevels: [] });
            groups.get(key).toplevels.push(toplevel);
        }

        return Array.from(groups.values()).map(group => ({
            appId: group.appId,
            pinned: group.pinned,
            toplevels: group.toplevels,
            active: root.activeToplevel ? group.toplevels.includes(root.activeToplevel) : false
        })).sort((left, right) => {
            if (left.pinned !== right.pinned)
                return left.pinned ? -1 : 1;
            return left.appId.localeCompare(right.appId);
        });
    }

    Timer { id: writeTimer; interval: 100; onTriggered: dockPinsFile.writeAdapter() }

    FileView {
        id: dockPinsFile
        path: root.pinsPath
        watchChanges: true
        onFileChanged: dockPinsFile.reload()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) dockPinsFile.writeAdapter(); }
        adapter: JsonAdapter { id: dockPins; property list<string> pinnedApps: [] }
    }

    function normalizedAppId(appId) { return String(appId ?? "").toLowerCase(); }
    function appIdForToplevel(toplevel) { return toplevel?.appId?.length > 0 ? toplevel.appId : "unknown"; }
    function launchApp(appId) { root.desktopEntryForApp(appId)?.execute(); }
    function desktopEntryForApp(appId) {
        return appId && appId.length > 0 ? (DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? null) : null;
    }

    function isPinned(appId) {
        const key = root.normalizedAppId(appId);
        return key.length > 0 && dockPins.pinnedApps.some(pinnedApp => root.normalizedAppId(pinnedApp) === key);
    }

    function togglePinned(appId) {
        const key = root.normalizedAppId(appId);
        if (key.length === 0)
            return;
        dockPins.pinnedApps = root.isPinned(appId)
            ? dockPins.pinnedApps.filter(pinnedApp => root.normalizedAppId(pinnedApp) !== key)
            : dockPins.pinnedApps.concat([appId]);
    }

    function desktopEntryForGroup(appGroup) {
        return appGroup?.desktopEntry
            ?? root.desktopEntryForApp(appGroup?.appId ?? "")
            ?? appGroup?.tray?.desktopEntry
            ?? null;
    }

    function appNameForApp(appId) {
        const entry = root.desktopEntryForApp(appId);
        if (entry?.name?.length > 0)
            return entry.name;
        const shortName = String(appId ?? "").split(".").pop() || "Application";
        return shortName.replace(/[-_]+/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
    }

    function appNameForGroup(appGroup) {
        const entry = root.desktopEntryForGroup(appGroup);
        if (entry?.name?.length > 0)
            return entry.name;
        const trayTitle = String(appGroup?.tray?.item?.title ?? "").trim();
        if (trayTitle.length > 0)
            return trayTitle;
        if ((appGroup?.appId?.length ?? 0) > 0)
            return root.appNameForApp(appGroup.appId);
        return String(appGroup?.tray?.item?.id ?? "").replace(/[-_]+/g, " ") || "Application";
    }

    function entryIconSource(entry) {
        if (!entry?.icon)
            return "";
        return Quickshell.iconPath(entry.icon.replace(/-symbolic$/, ""), true) || Quickshell.iconPath(entry.icon, true);
    }

    function iconSourceForApp(appId) {
        const entryIcon = root.entryIconSource(root.desktopEntryForApp(appId));
        if (entryIcon.length > 0)
            return entryIcon;
        const raw = String(appId ?? "");
        const shortName = raw.split(".").pop() || "";
        for (const candidate of [raw, raw.toLowerCase(), shortName, shortName.toLowerCase(), raw.toLowerCase().replace(/\s+/g, "-"), "application-x-executable"]) {
            const source = candidate ? Quickshell.iconPath(candidate, true) : "";
            if (source.length > 0)
                return source;
        }
        return "";
    }

    function iconSourceForGroup(appGroup) {
        const entryIcon = root.entryIconSource(root.desktopEntryForGroup(appGroup));
        if (entryIcon.length > 0)
            return entryIcon;
        const trayIcon = String(appGroup?.tray?.item?.icon ?? "");
        if (trayIcon.length > 0)
            return trayIcon;
        return (appGroup?.appId?.length ?? 0) > 0
            ? root.iconSourceForApp(appGroup.appId)
            : Quickshell.iconPath("application-x-executable", true);
    }

    function desktopActionsForGroup(appGroup) {
        return (root.desktopEntryForGroup(appGroup)?.actions ?? [])
            .filter(action => {
                const title = String(action?.name ?? "").trim();
                return title.length > 0 && !/^open(\s+new)?\s+window$/i.test(title) && !/^new\s+window$/i.test(title);
            })
            .map(action => ({
                title: String(action.name).trim(),
                iconSource: action?.icon ? Quickshell.iconPath(String(action.icon), true) : "",
                action: action
            }));
    }

    function menuForGroup(appGroup) {
        const trayItem = appGroup?.tray?.item ?? null;
        if (trayItem?.hasMenu && trayItem.menu)
            return trayItem.menu;
        const rev = AppMenuRegistrar.revision;
        const key = root.normalizedAppId(appGroup?.appId ?? "");
        if (rev < 0 || key.length === 0)
            return null;
        for (const hlToplevel of Hyprland.toplevels.values) {
            const ipc = hlToplevel.lastIpcObject;
            const pid = Number(ipc?.pid ?? 0);
            if (pid > 0 && (root.normalizedAppId(ipc?.class) === key || root.normalizedAppId(ipc?.initialClass) === key)) {
                const menu = AppMenuRegistrar.menuForPid(pid);
                if (menu)
                    return menu;
            }
        }
        return null;
    }

    function pidForGroup(appGroup) {
        const key = root.normalizedAppId(appGroup?.appId ?? "");
        if (key.length === 0)
            return 0;
        for (const hlToplevel of Hyprland.toplevels.values) {
            const ipc = hlToplevel.lastIpcObject;
            const pid = Number(ipc?.pid ?? 0);
            if (pid > 0 && (root.normalizedAppId(ipc?.class) === key || root.normalizedAppId(ipc?.initialClass) === key))
                return pid;
        }
        return 0;
    }

    function gtkActionsForGroup(appGroup) {
        const pid = root.pidForGroup(appGroup);
        return pid > 0 ? (root.gtkActionsByPid[pid] ?? []) : [];
    }

    function ensureGtkActionsForGroup(appGroup) {
        const pid = root.pidForGroup(appGroup);
        if (pid <= 0 || root.gtkActionsByPid[pid] !== undefined)
            return;
        root.pendingGtkPid = pid;
        if (!gtkListProcess.running)
            root.startNextGtkQuery();
    }

    function startNextGtkQuery() {
        if (gtkListProcess.running || root.pendingGtkPid <= 0)
            return;
        const pid = root.pendingGtkPid;
        root.pendingGtkPid = 0;
        gtkListProcess.queriedPid = pid;
        gtkListProcess.exec(["quickshell-gtk-actions", "list", String(pid)]);
    }

    function activateGtkAction(item) {
        if (item?.service && item?.path && item?.action)
            gtkActivateProcess.exec(["quickshell-gtk-actions", "activate", item.service, item.path, item.action]);
    }

    Process {
        id: gtkListProcess
        property int queriedPid: 0
        stdout: StdioCollector { id: gtkListOutput }
        onExited: (exitCode, exitStatus) => {
            const pid = gtkListProcess.queriedPid;
            if (pid > 0) {
                const next = Object.assign({}, root.gtkActionsByPid);
                next[pid] = exitCode === 0 ? TrayApps.parseGtkActions(gtkListOutput.text) : [];
                root.gtkActionsByPid = next;
            }
            Qt.callLater(() => root.startNextGtkQuery());
        }
    }

    Process { id: gtkActivateProcess }
}
