pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as ShellConfig

/**
 * Backend service for launcher file search, clipboard history, and external copy/open actions.
 */
Scope {
    id: root

    required property bool open
    required property string mode
    required property string query

    property var clipboardItems: []
    property var fileItems: []
    property string selectedFileDir: ""
    property bool fileSearchLoading: false
    property string fileSearchError: ""
    property bool fileSearchQueued: false
    property var activeFileRequest: null
    property bool clipboardLoading: false
    property string clipboardError: ""
    property bool clipboardQueued: false

    readonly property var fileSearchPaths: ShellConfig.Config.launcher.fileSearchPaths

    function initialFileDirectory() { return root.fileSearchPaths.length === 1 ? root.fileSearchPaths[0] : ""; }

    function currentFileRequest() {
        const trimmed = root.query.trim();
        return { query: trimmed, directory: root.selectedFileDir, key: `${root.selectedFileDir}\u0000${trimmed}` };
    }

    function stopFileSearch() {
        fileSearchTimer.stop();
        root.fileSearchQueued = false;
        root.fileSearchLoading = false;
    }

    function parseClipboardItems(text) {
        return text.split("\n").filter(line => line.length > 0).slice(0, 20).map(line => {
            const tabIndex = line.indexOf("\t");
            const label = tabIndex >= 0 ? line.slice(tabIndex + 1) : line;
            const title = label.replace(/\s+/g, " ").trim();
            return {
                kind: "clipboard", title: title.length > 0 ? title : "Copied item",
                subtitle: "Copy item", raw: line, search: title.toLowerCase()
            };
        });
    }

    function parseFileItems(text) {
        return text.split("\0").filter(line => line.startsWith("directory\t") || line.startsWith("file\t")).map(entry => {
            const tabIndex = entry.indexOf("\t");
            const kind = entry.slice(0, tabIndex);
            const path = entry.slice(tabIndex + 1);
            const slash = path.lastIndexOf("/");
            const title = slash >= 0 ? path.slice(slash + 1) : path;
            const directory = slash >= 0 ? path.slice(0, slash) : "";
            const homePrefix = `${Quickshell.env("HOME")}/`;
            const subtitle = directory.startsWith(homePrefix) ? `~/${directory.slice(homePrefix.length)}` : directory;
            return {
                kind: kind, title: title.length > 0 ? title : path,
                subtitle: kind === "directory" ? "Select folder" : subtitle,
                path: path, search: `${title} ${subtitle}`.toLowerCase()
            };
        });
    }

    function refreshFiles() {
        if (!root.open || root.mode !== "files") return;
        root.fileSearchLoading = true;
        fileSearchTimer.restart();
    }

    function startFileSearch() {
        if (!root.open || root.mode !== "files") return;
        if (fileSearchProcess.running) {
            root.fileSearchQueued = true;
            return;
        }
        const request = root.currentFileRequest();
        const query = request.query;
        const selectedDirectory = request.directory;
        root.activeFileRequest = request;
        root.fileSearchLoading = true;
        root.fileSearchError = "";
        fileSearchProcess.environment = ({
            FILE_QUERY: query,
            FILE_DIR: selectedDirectory,
            FILE_WHITELIST: `${ShellConfig.Config.launcher.configDir}/whitelist.txt`,
            FILE_BLACKLIST: `${ShellConfig.Config.launcher.configDir}/blacklist.txt`
        });
        fileSearchProcess.exec(["quickshell-file-search", query, selectedDirectory]);
    }

    function refreshClipboard() {
        if (!root.open || root.mode !== "clipboard") {
            root.clipboardQueued = false;
            root.clipboardLoading = false;
            return;
        }
        if (clipboardListProcess.running) {
            root.clipboardQueued = true;
            return;
        }
        root.clipboardLoading = true;
        root.clipboardError = "";
        clipboardListProcess.exec(["cliphist", "list"]);
    }

    function copyText(value) { copyProcess.exec(["wl-copy", value]); }
    function openFile(path) { fileOpenProcess.exec(["xdg-open", path]); }
    function copyFileUri(path) {
        const uri = `file://${encodeURIComponent(path).replace(/%2F/gi, "/")}`;
        copyProcess.exec(["wl-copy", "--type", "text/uri-list", `${uri}\n`]);
    }
    function copyClipboardEntry(rawEntry) {
        copyProcess.exec({
            command: ["sh", "-c", "printf %s \"$CLIPHIST_ENTRY\" | cliphist decode | wl-copy"],
            environment: ({ CLIPHIST_ENTRY: rawEntry })
        });
    }

    Timer { id: fileSearchTimer; interval: 120; onTriggered: root.startFileSearch() }

    Process {
        id: clipboardListProcess
        stdout: StdioCollector { id: clipboardOutput }
        stderr: StdioCollector { id: clipboardErrorOutput }
        onExited: (exitCode, exitStatus) => {
            const hasQueuedRequest = root.clipboardQueued;
            root.clipboardLoading = hasQueuedRequest;
            if (!hasQueuedRequest && root.open && root.mode === "clipboard") {
                if (exitCode === 0) root.clipboardItems = root.parseClipboardItems(clipboardOutput.text);
                else root.clipboardError = clipboardErrorOutput.text.trim() || "Clipboard history unavailable";
            }
            if (root.clipboardQueued) {
                root.clipboardQueued = false;
                if (root.open && root.mode === "clipboard") Qt.callLater(() => root.refreshClipboard());
                else root.clipboardLoading = false;
            }
        }
    }

    Process {
        id: fileSearchProcess
        stdout: StdioCollector { id: fileSearchOutput }
        stderr: StdioCollector { id: fileSearchErrorOutput }
        onExited: (exitCode, exitStatus) => {
            const request = root.activeFileRequest;
            const hasQueuedRequest = root.fileSearchQueued && root.open && root.mode === "files";
            root.activeFileRequest = null;
            root.fileSearchLoading = hasQueuedRequest;
            if (!hasQueuedRequest && request !== null && request.key === root.currentFileRequest().key && root.open && root.mode === "files") {
                if (exitCode === 0) root.fileItems = root.parseFileItems(fileSearchOutput.text);
                else root.fileSearchError = fileSearchErrorOutput.text.trim() || "File search unavailable";
            }
            if (root.fileSearchQueued) {
                root.fileSearchQueued = false;
                if (root.open && root.mode === "files") Qt.callLater(() => root.startFileSearch());
                else root.fileSearchLoading = false;
            }
        }
    }

    Process { id: copyProcess }
    Process { id: fileOpenProcess }
}
