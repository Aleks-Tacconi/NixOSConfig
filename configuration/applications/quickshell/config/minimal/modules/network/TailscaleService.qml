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
    property bool pollingActive: false
    property string errorText: ""

    Timer {
        interval: 5000
        repeat: true
        running: ShellConfig.Config.network.tailscale && root.pollingActive
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: toggleTimeout
        interval: 15000
        onTriggered: {
            if (!toggleProcess.running)
                return;
            toggleProcess.running = false;
            root.pending = false;
            root.errorText = "Tailscale request timed out. Run 'tailscale up' in a terminal if login is required.";
        }
    }

    Process {
        id: statusProcess

        stdout: StdioCollector {
            id: statusOutput
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.applyStatus(statusOutput.text);
            else
                root.connected = false;
        }
    }

    Process {
        id: toggleProcess

        stderr: StdioCollector { id: toggleError }

        onExited: (exitCode, exitStatus) => {
            const timedOut = !root.pending;
            toggleTimeout.stop();
            if (timedOut)
                return;
            root.errorText = exitCode === 0 ? "" : (toggleError.text.trim() || "Could not change VPN state. Check Tailscale permissions and try again.");
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
        root.errorText = "";
        root.pending = true;
        toggleTimeout.restart();
        toggleProcess.exec(["tailscale", root.connected ? "down" : "up"]);
    }
}
