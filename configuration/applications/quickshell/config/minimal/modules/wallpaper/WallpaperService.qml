pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/** Validate wallpaper selections and remember the last applied image. */
Scope {
    id: root

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`
    readonly property string fallback: `file://${root.dataHome}/wallpapers/cypberpunk.jpg`
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`
    property string current: root.fallback
    property string previous: root.fallback
    property string pending: ""
    property string error: ""
    readonly property bool busy: root.pending.length > 0 || themeProcess.running

    /** Mirror the active wallpaper to a greeter-readable cache path. */
    function syncGreeterWallpaper(source) {
        if (!source || !source.startsWith("file://"))
            return;
        const path = decodeURIComponent(source.replace(/^file:\/\//, ""));
        greeterWallpaperProcess.exec([
            "sh", "-c",
            "dir=/var/cache/greeter-wallpaper; [ -d \"$dir\" ] && [ -w \"$dir\" ] || exit 0; tmp=\"$dir/.current.tmp.$$\"; cp -f \"$1\" \"$tmp\" && chmod 644 \"$tmp\" && mv -f \"$tmp\" \"$dir/current\"",
            "sh", path
        ]);
    }

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
                root.syncGreeterWallpaper(root.current);
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

    Process {
        id: greeterWallpaperProcess
    }

    FileView {
        id: stateFile
        path: `${root.stateHome}/quickshell/wallpaper.json`
        printErrors: false
        onLoaded: {
            if (savedState.wallpaper.length > 0) {
                root.previous = savedState.wallpaper;
                root.current = savedState.wallpaper;
            }
            root.syncGreeterWallpaper(root.current);
        }
        onSaveFailed: root.error = "Wallpaper applied, but the selection could not be saved."
        adapter: JsonAdapter {
            id: savedState
            property string wallpaper: ""
        }
    }
}
