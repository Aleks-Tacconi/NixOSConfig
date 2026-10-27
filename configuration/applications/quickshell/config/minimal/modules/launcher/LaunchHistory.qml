pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "search.js" as Search

/** Share persisted launcher usage between screens without background polling. */
Scope {
    id: root

    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`
    readonly property var apps: history.apps

    /** Remember an application launched from this launcher. */
    function record(id) {
        history.apps = Search.recordLaunch(history.apps, id, Date.now());
        historyFile.writeAdapter();
    }

    FileView {
        id: historyFile
        path: `${root.stateHome}/quickshell/launcher-history.json`
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Could not read launcher history:", error);
        }
        onSaveFailed: console.warn("Could not save launcher history")
        adapter: JsonAdapter {
            id: history
            property var apps: ({})
        }
    }
}
