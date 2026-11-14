pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/** Validate wallpaper selections and remember the last applied image. */
Scope {
    id: root

    readonly property string fallback: `file://${Quickshell.env("HOME")}/.hyprland-assets/wallpaper.jpg`
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`
    property string current: root.fallback
    property string previous: root.fallback
    property string pending: ""
    property string error: ""
    readonly property bool busy: root.pending.length > 0 || themeProcess.running

    /** Load before changing the desktop so broken images leave it intact. */
    function apply(source) {
        if (root.busy || source === root.current)
            return;
        root.error = "";
        root.pending = source;
    }

    Image {
        id: probe
        visible: false
        asynchronous: true
        source: root.pending
        sourceSize.width: 64
        sourceSize.height: 64
        onStatusChanged: {
            if (probe.status === Image.Ready) {
                root.previous = root.current;
                root.current = root.pending;
                root.pending = "";
                savedState.wallpaper = root.current;
                stateFile.writeAdapter();
                themeProcess.exec(["quickshell-wallpaper-theme", decodeURIComponent(root.current.replace(/^file:\/\//, ""))]);
            } else if (probe.status === Image.Error) {
                root.error = "Could not load this wallpaper. Choose another image.";
                root.pending = "";
            }
        }
    }

    Process {
        id: themeProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.error = "Wallpaper applied, but Qt/KDE colors could not be updated.";
        }
    }

    FileView {
        id: stateFile
        path: `${root.stateHome}/quickshell/wallpaper.json`
        printErrors: false
        onLoaded: {
            if (savedState.wallpaper.length > 0)
                root.apply(savedState.wallpaper);
        }
        onSaveFailed: root.error = "Wallpaper applied, but the selection could not be saved."
        adapter: JsonAdapter {
            id: savedState
            property string wallpaper: ""
        }
    }
}
