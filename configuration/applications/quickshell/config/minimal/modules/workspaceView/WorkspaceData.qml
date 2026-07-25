pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Tracks Hyprland clients and workspaces for the overview.
 */
Scope {
    id: root

    property var windowList: []
    property var monitors: []
    property var monitorById: ({})
    property var workspaces: []
    property var workspaceById: ({})
    property var workspaceIds: []
    property var windowByAddress: ({})
    property var activeWorkspace: null
    readonly property var activeToplevel: ToplevelManager.activeToplevel

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel)
            return null

        return root.windowByAddress[`0x${toplevel.HyprlandToplevel.address}`] ?? null
    }

    function toplevelsForWorkspace(workspaceId) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const client = root.clientForToplevel(toplevel)
            return client?.workspace?.id === workspaceId
        })
    }

    function previewToplevelsForWorkspace(workspaceId) {
        return root.toplevelsForWorkspace(workspaceId)
    }

    function monitorForWorkspace(workspaceId) {
        const workspace = root.workspaceById[workspaceId]

        return workspace ? root.monitorById[workspace.monitorID] : null
    }

    function updateAll() {
        getClients.running = true
        getMonitors.running = true
        getWorkspaces.running = true
        getActiveWorkspace.running = true
    }

    function parseJson(text, fallback) {
        try {
            return JSON.parse(text)
        } catch (error) {
            return fallback
        }
    }

    Component.onCompleted: {
        root.updateAll()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].includes(event.name))
                return

            root.updateAll()
        }
    }

    Process {
        id: getClients

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            id: clientsCollector

            onStreamFinished: {
                root.windowList = root.parseJson(clientsCollector.text, [])

                const windowsByAddress = {}

                for (const client of root.windowList)
                    windowsByAddress[client.address] = client

                root.windowByAddress = windowsByAddress
            }
        }
    }

    Process {
        id: getWorkspaces

        command: ["hyprctl", "workspaces", "-j"]

        stdout: StdioCollector {
            id: workspacesCollector

            onStreamFinished: {
                const rawWorkspaces = root.parseJson(workspacesCollector.text, [])
                const workspacesById = {}

                root.workspaces = rawWorkspaces.filter(workspace => workspace.id >= 1 && workspace.id <= 100)
                root.workspaceIds = root.workspaces.map(workspace => workspace.id)

                for (const workspace of root.workspaces)
                    workspacesById[workspace.id] = workspace

                root.workspaceById = workspacesById
            }
        }
    }

    Process {
        id: getMonitors

        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            id: monitorsCollector

            onStreamFinished: {
                root.monitors = root.parseJson(monitorsCollector.text, [])

                const monitorsById = {}

                for (const monitor of root.monitors)
                    monitorsById[monitor.id] = monitor

                root.monitorById = monitorsById
            }
        }
    }

    Process {
        id: getActiveWorkspace

        command: ["hyprctl", "activeworkspace", "-j"]

        stdout: StdioCollector {
            id: activeWorkspaceCollector

            onStreamFinished: {
                root.activeWorkspace = root.parseJson(activeWorkspaceCollector.text, null)
            }
        }
    }
}
