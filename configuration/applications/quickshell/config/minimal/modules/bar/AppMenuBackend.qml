pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/** Own app-menu subprocesses and timeout independently of presentation. */
Scope {
    id: root

    required property var owner
    property alias activeWindowProcess: activeWindowProcess
    property alias gtkListProcess: gtkListProcess
    property alias gtkActivateProcess: gtkActivateProcess
    property alias qtMenuProbeProcess: qtMenuProbeProcess
    property alias killProcess: killProcess
    property alias actionResolutionDeadline: actionResolutionDeadline

    Process {
        id: activeWindowProcess

        property var request: null

        stdout: StdioCollector {
            id: activeWindowOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.owner.finishWindowRequest(activeWindowProcess.request, exitCode, activeWindowOutput.text);
            activeWindowProcess.request = null;
            Qt.callLater(() => root.owner.startPendingWindowRequest());
        }
    }

    Process {
        id: gtkListProcess

        property var request: null

        stdout: StdioCollector {
            id: gtkListOutput
        }

        onExited: (exitCode, exitStatus) => {
            root.owner.finishGtkRequest(gtkListProcess.request, exitCode, gtkListOutput.text);
            gtkListProcess.request = null;
            Qt.callLater(() => root.owner.startPendingGtkRequest());
        }
    }

    Process {
        id: gtkActivateProcess

        property var request: null

        onExited: {
            gtkActivateProcess.request = null;
            Qt.callLater(() => root.owner.startPendingActivationRequest());
        }
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
            Qt.callLater(() => root.owner.finishDeferredGtkRequest());
            Qt.callLater(() => root.owner.startPendingNativeMenuProbe());
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
