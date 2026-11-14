pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/** Own app-menu subprocesses, queues, and resolution timeout independently of presentation. */
Scope {
    id: root

    required property var owner
    property var pendingWindowRequest: null
    property var pendingGtkRequest: null
    property var deferredGtkOutput: null
    property var pendingActivationRequest: null
    property int pendingNativeProbePid: 0

    function resetQueues() {
        actionResolutionDeadline.stop();
        root.pendingWindowRequest = null;
        root.pendingGtkRequest = null;
        root.deferredGtkOutput = null;
    }

    function startDeadline() {
        actionResolutionDeadline.restart();
    }

    function stopDeadline() {
        actionResolutionDeadline.stop();
    }

    function requestWindow(request) {
        root.pendingWindowRequest = request;
        root.startPendingWindowRequest();
    }

    function startPendingWindowRequest() {
        if (activeWindowProcess.running || root.pendingWindowRequest === null)
            return;

        const request = root.pendingWindowRequest;
        root.pendingWindowRequest = null;
        if (!root.owner.requestIsCurrent(request))
            return;

        activeWindowProcess.request = request;
        activeWindowProcess.exec(["hyprctl", "activewindow", "-j"]);
    }

    function requestGtk(request) {
        root.pendingGtkRequest = request;
        root.startPendingGtkRequest();
    }

    function startPendingGtkRequest() {
        if (gtkListProcess.running || root.pendingGtkRequest === null)
            return;

        const request = root.pendingGtkRequest;
        root.pendingGtkRequest = null;
        if (!root.owner.requestIsCurrent(request) || request.pid <= 0)
            return;

        gtkListProcess.request = request;
        gtkListProcess.exec(["quickshell-gtk-actions", "list", String(request.pid)]);
    }

    function activateGtk(service, path, action) {
        root.pendingActivationRequest = Object.freeze({
            service: service,
            path: path,
            action: action
        });
        root.startPendingActivationRequest();
    }

    function startPendingActivationRequest() {
        if (gtkActivateProcess.running || root.pendingActivationRequest === null)
            return;

        const request = root.pendingActivationRequest;
        root.pendingActivationRequest = null;
        gtkActivateProcess.exec(["quickshell-gtk-actions", "activate", request.service, request.path, request.action]);
    }

    function probeNativeMenu(pid) {
        root.pendingNativeProbePid = pid;
        root.startPendingNativeMenuProbe();
    }

    function startPendingNativeMenuProbe() {
        if (qtMenuProbeProcess.running || root.pendingNativeProbePid <= 0)
            return;

        const pid = root.pendingNativeProbePid;
        root.pendingNativeProbePid = 0;
        if (pid !== root.owner.activePid)
            return;

        qtMenuProbeProcess.probedPid = pid;
        qtMenuProbeProcess.exec(["quickshell-qt-menu", String(pid)]);
    }

    function flushDeferredGtk() {
        const deferred = root.deferredGtkOutput;
        root.deferredGtkOutput = null;
        if (deferred !== null)
            root.owner.finishGtkRequest(deferred.request, deferred.exitCode, deferred.output);
    }

    function killPid(pid) {
        if (pid > 0)
            killProcess.exec(["kill", "-9", String(pid)]);
    }

    Process {
        id: activeWindowProcess

        property var request: null

        stdout: StdioCollector {
            id: activeWindowOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.owner.finishWindowRequest(activeWindowProcess.request, exitCode, activeWindowOutput.text);
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
            const req = gtkListProcess.request;
            gtkListProcess.request = null;
            if (req !== null && qtMenuProbeProcess.running && qtMenuProbeProcess.probedPid === req.pid)
                root.deferredGtkOutput = Object.freeze({ request: req, exitCode: exitCode, output: gtkListOutput.text });
            else
                root.owner.finishGtkRequest(req, exitCode, gtkListOutput.text);
            Qt.callLater(() => root.startPendingGtkRequest());
        }
    }

    Process {
        id: gtkActivateProcess

        onExited: Qt.callLater(() => root.startPendingActivationRequest())
    }

    Process {
        id: qtMenuProbeProcess

        property int probedPid: 0

        stdout: StdioCollector {
            id: qtMenuProbeOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.owner.finishNativeMenuProbe(qtMenuProbeProcess.probedPid, exitCode, qtMenuProbeOutput.text);
            qtMenuProbeProcess.probedPid = 0;
            Qt.callLater(() => root.flushDeferredGtk());
            Qt.callLater(() => root.startPendingNativeMenuProbe());
        }
    }

    Process {
        id: killProcess
    }

    Timer {
        id: actionResolutionDeadline

        interval: 2000
        onTriggered: {
            const request = root.owner.actionRequest;
            if (request !== null && root.owner.actionResolving)
                root.owner.finalizeActionRequest(request, [], true);
        }
    }
}
