pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Shared NetworkManager state and actions for all bar instances.
 */
Scope {
    id: root

    property string interfaceName: ""
    property string wifiInterface: ""
    property string networkType: "none"
    property string networkState: "unavailable"
    property string networkLabel: "No network"
    property bool wifiEnabled: false
    property var networks: []
    property bool scanPending: false
    property bool actionPending: false
    property string actionNetworkBssid: ""
    property string errorText: ""
    readonly property real downloadBytesPerSecond: traffic.downloadBytesPerSecond
    readonly property real uploadBytesPerSecond: traffic.uploadBytesPerSecond
    readonly property bool tailscaleConnected: tailscale.connected
    readonly property bool tailscalePending: tailscale.pending
    property bool scanAfterStatus: false
    property bool queuedScan: false
    property bool queuedRescan: false

    signal passwordRequested(var network)
    signal actionSucceeded


    NetworkTraffic {
        id: traffic

        interfaceName: root.interfaceName
    }

    TailscaleService {
        id: tailscale
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    Process {
        id: statusProcess

        stdout: StdioCollector {
            id: statusOutput
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.applyStatus(statusOutput.text);
            if (root.scanAfterStatus) {
                const force = root.queuedRescan;
                root.scanAfterStatus = false;
                root.queuedRescan = false;
                if (root.wifiInterface.length > 0)
                    root.requestScan(force);
                else
                    root.networks = [];
            }
        }
    }

    Process {
        id: scanProcess

        stdout: StdioCollector {
            id: scanOutput
        }
        stderr: StdioCollector {
            id: scanError
        }

        onExited: (exitCode, exitStatus) => {
            root.scanPending = false;
            if (exitCode === 0)
                root.applyScan(scanOutput.text);
            else
                root.errorText = root.cleanError(scanError.text);
            if (root.queuedScan) {
                const force = root.queuedRescan;
                root.queuedScan = false;
                root.queuedRescan = false;
                Qt.callLater(() => root.requestScan(force));
            }
        }
    }

    Process {
        id: actionProcess

        property var request: null
        stdinEnabled: true
        stderr: StdioCollector {
            id: actionError
        }

        onExited: (exitCode, exitStatus) => {
            const request = actionProcess.request;
            actionProcess.request = null;
            root.actionPending = false;
            root.actionNetworkBssid = "";
            if (exitCode === 0) {
                root.errorText = "";
                root.actionSucceeded();
                root.scanAfterStatus = true;
                root.queuedRescan = false;
                root.refreshStatus();
            } else {
                root.errorText = root.cleanError(actionError.text);
                if (exitCode === 20 && request?.retryWithPassword)
                    root.passwordRequested(request.network);
            }
        }
    }

    Process {
        id: settingsProcess
    }

    function refreshStatus() {
        if (!statusProcess.running)
            statusProcess.exec(["quickshell-network-control", "status"]);
    }

    function applyStatus(output) {
        try {
            const status = JSON.parse(output);
            root.interfaceName = status.interfaceName ?? "";
            root.wifiInterface = status.wifiInterface ?? "";
            root.networkType = status.type ?? "none";
            root.networkState = status.state ?? "unavailable";
            root.networkLabel = status.label ?? "No network";
            root.wifiEnabled = status.wifiEnabled ?? false;
        } catch (error) {
            console.warn("Unable to parse NetworkManager status", error);
        }
    }

    function requestScan(rescan = false) {
        if (scanProcess.running) {
            root.queuedScan = true;
            root.queuedRescan = root.queuedRescan || rescan;
            return;
        }
        if (root.wifiInterface.length === 0) {
            root.scanAfterStatus = true;
            root.queuedRescan = rescan;
            root.refreshStatus();
            return;
        }
        if (!root.wifiEnabled) {
            root.networks = [];
            return;
        }

        root.scanPending = true;
        root.errorText = "";
        const command = ["quickshell-network-control", "scan", "--interface", root.wifiInterface];
        if (rescan)
            command.push("--rescan");
        scanProcess.exec(command);
    }

    function applyScan(output) {
        try {
            root.networks = JSON.parse(output);
        } catch (error) {
            root.networks = [];
            root.errorText = "Unable to read available networks";
        }
    }

    function startAction(command, request = null, password = "") {
        if (root.actionPending)
            return;
        root.actionPending = true;
        root.actionNetworkBssid = request !== null && request.network ? request.network.bssid : "";
        root.errorText = "";
        actionProcess.request = request;
        actionProcess.exec(command);
        if (password.length > 0) {
            actionProcess.write(password + "\n");
            actionProcess.closeStdin();
        }
    }

    function activate(network) {
        if (network.active) {
            root.disconnectWifi(network);
            return;
        }
        if (!network.supported) {
            root.openSettings();
            return;
        }
        if (network.requiresPassword && network.savedUuid.length === 0) {
            root.passwordRequested(network);
            return;
        }
        const command = ["quickshell-network-control", "connect", "--interface", root.wifiInterface, "--bssid", network.bssid];
        root.startAction(command, {
            network: network,
            retryWithPassword: network.requiresPassword
        });
    }

    function activateWithPassword(network, password) {
        root.startAction([
            "quickshell-network-control", "connect", "--interface", root.wifiInterface,
            "--bssid", network.bssid, "--password-stdin"
        ], {
            network: network,
            retryWithPassword: false
        }, password);
    }

    function activateHidden(ssid, secured, password) {
        const command = [
            "quickshell-network-control", "connect-hidden", "--interface", root.wifiInterface,
            "--ssid", ssid
        ];
        if (secured)
            command.push("--password-stdin");
        root.startAction(command, null, password);
    }

    function disconnectWifi(network = null) {
        if (root.wifiInterface.length > 0)
            root.startAction(["quickshell-network-control", "disconnect", "--interface", root.wifiInterface], {
                network: network,
                retryWithPassword: false
            });
    }

    function setWifiEnabled(enabled) {
        root.startAction(["quickshell-network-control", "radio", enabled ? "on" : "off"]);
    }

    function openSettings() {
        if (!settingsProcess.running)
            settingsProcess.exec(["nm-connection-editor"]);
    }

    function clearError() {
        root.errorText = "";
    }

    function cleanError(output) {
        const message = output.trim().replace(/^Error:\s*/i, "");
        return message.length > 0 ? message : "Network operation failed";
    }

    function toggleTailscale() {
        tailscale.toggle();
    }
}
