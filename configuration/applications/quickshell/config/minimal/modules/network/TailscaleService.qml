pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as ShellConfig

/**
 * Poll and toggle the optional Tailscale connection.
 */
Scope {
    id: root

    property bool connected: false
    property bool pending: false

    Timer {
        interval: 5000
        repeat: true
        running: ShellConfig.Config.network.tailscale
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess

        stdout: StdioCollector {
            id: statusOutput
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.applyStatus(statusOutput.text);
        }
    }

    Process {
        id: toggleProcess

        onExited: {
            root.pending = false;
            root.refresh();
        }
    }

    function refresh() {
        if (ShellConfig.Config.network.tailscale && !statusProcess.running)
            statusProcess.exec(["tailscale", "status", "--json"]);
    }

    function applyStatus(output) {
        try {
            root.connected = JSON.parse(output).BackendState === "Running";
        } catch (error) {
            root.connected = false;
        }
    }

    function toggle() {
        if (root.pending)
            return;
        root.pending = true;
        toggleProcess.exec(["tailscale", root.connected ? "down" : "up"]);
    }
}
