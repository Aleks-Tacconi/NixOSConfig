pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * Groups open windows by application for the dock.
 */
Scope {
    id: root

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string stateHome: {
        const configuredStateHome = Quickshell.env("XDG_STATE_HOME") ?? "";

        return configuredStateHome.length > 0 ? configuredStateHome : `${Quickshell.env("HOME") ?? ""}/.local/state`;
    }
    readonly property string pinsPath: `${root.stateHome}/quickshell/dock-pins.json`
    readonly property var appGroups: {
        const groups = new Map()
        const pinnedApps = dockPins.pinnedApps ?? []

        for (const appId of pinnedApps) {
            const key = root.normalizedAppId(appId)

            if (!groups.has(key))
                groups.set(key, { appId, pinned: true, toplevels: [] })
        }

        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = root.appIdForToplevel(toplevel)
            const key = root.normalizedAppId(appId)

            if (!groups.has(key))
                groups.set(key, { appId, pinned: false, toplevels: [] })

            groups.get(key).toplevels.push(toplevel)
        }

        return Array.from(groups.values()).map(group => ({
            appId: group.appId,
            pinned: group.pinned,
            toplevels: group.toplevels,
            active: root.activeToplevel ? group.toplevels.includes(root.activeToplevel) : false,
        })).sort((left, right) => {
            if (left.pinned !== right.pinned)
                return left.pinned ? -1 : 1

            return left.appId.localeCompare(right.appId)
        })
    }

    Timer {
        id: writeTimer

        interval: 100
        onTriggered: dockPinsFile.writeAdapter()
    }

    FileView {
        id: dockPinsFile

        path: root.pinsPath
        watchChanges: true
        onFileChanged: dockPinsFile.reload()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                dockPinsFile.writeAdapter()
        }

        adapter: JsonAdapter {
            id: dockPins

            property list<string> pinnedApps: []
        }
    }

    function normalizedAppId(appId) {
        return appId.toLowerCase()
    }

    function appIdForToplevel(toplevel) {
        return toplevel?.appId?.length > 0 ? toplevel.appId : "unknown"
    }

    function isPinned(appId) {
        const key = root.normalizedAppId(appId)
        return dockPins.pinnedApps.some(pinnedApp => root.normalizedAppId(pinnedApp) === key)
    }

    function togglePinned(appId) {
        const key = root.normalizedAppId(appId)

        if (root.isPinned(appId)) {
            dockPins.pinnedApps = dockPins.pinnedApps.filter(pinnedApp => root.normalizedAppId(pinnedApp) !== key)
            return
        }

        dockPins.pinnedApps = dockPins.pinnedApps.concat([appId])
    }

    function launchApp(appId) {
        const desktopEntry = root.desktopEntryForApp(appId)

        desktopEntry?.execute()
    }

    function desktopEntryForApp(appId) {
        return DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? null
    }

    function appNameForApp(appId) {
        const entry = root.desktopEntryForApp(appId)
        if (entry?.name?.length > 0)
            return entry.name

        const shortName = appId.split(".").pop() || "Application"
        return shortName.replace(/[-_]+/g, " ").replace(/\b\w/g, letter => letter.toUpperCase())
    }

    function desktopActionsForApp(appId) {
        const actions = root.desktopEntryForApp(appId)?.actions ?? []
        const result = []

        for (let index = 0; index < actions.length && result.length < 3; index++) {
            const action = actions[index]
            const title = String(action.name ?? "").trim()
            const normalizedId = String(action.id ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "")
            if (title.length > 0 && normalizedId !== "newwindow")
                result.push(action)
        }

        return result
    }

    function iconSourceForApp(appId) {
        const desktopEntry = root.desktopEntryForApp(appId)

        if (desktopEntry?.icon) {
            const desktopIcon = Quickshell.iconPath(desktopEntry.icon, true)

            if (desktopIcon.length > 0)
                return desktopIcon
        }

        const shortName = appId.split(".").pop()
        const candidates = [
            appId,
            appId.toLowerCase(),
            shortName,
            shortName.toLowerCase(),
            appId.toLowerCase().replace(/\s+/g, "-"),
            "application-x-executable",
        ]

        for (const candidate of candidates) {
            const source = Quickshell.iconPath(candidate, true)

            if (source.length > 0)
                return source
        }

        return ""
    }
}
