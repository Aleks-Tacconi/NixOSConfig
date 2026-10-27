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
    readonly property color accent: shellPalette.accent
    property string current: root.fallback
    property string previous: root.fallback
    property string pending: ""
    property string error: ""
    readonly property bool busy: root.pending.length > 0 || settleTimer.running || themeProcess.running

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
                saved.wallpaper = root.current;
                stateFile.writeAdapter();
                settleTimer.restart();
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
            paletteFile.reload();
            if (exitCode !== 0)
                root.error = "Wallpaper applied, but Qt/KDE colors could not be updated.";
        }
    }

    Timer {
        id: settleTimer
        interval: 900
    }

    FileView {
        id: paletteFile
        path: `${root.stateHome}/quickshell/wallpaper-theme/shell-palette.json`
        watchChanges: true
        printErrors: false
        onFileChanged: paletteFile.reload()
        adapter: JsonAdapter {
            id: shellPalette
            property string accent: "white"
        }
    }

    FileView {
        id: stateFile
        path: `${root.stateHome}/quickshell/wallpaper.json`
        printErrors: false
        onLoaded: {
            if (saved.wallpaper.length > 0)
                root.apply(saved.wallpaper);
        }
        onSaveFailed: root.error = "Wallpaper applied, but the selection could not be saved."
        adapter: JsonAdapter {
            id: saved
            property string wallpaper: ""
        }
    }
}
