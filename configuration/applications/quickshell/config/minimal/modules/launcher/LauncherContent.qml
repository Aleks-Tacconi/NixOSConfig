pragma ComponentBehavior: Bound

import QtQuick
import "search.js" as Search
import Quickshell
import Quickshell.Io
import "../../theme"
import "../.." as ShellConfig

/**
 * Searchable launcher content with mode switching.
 */
Item {
    id: root

    required property bool open
    required property string mode
    required property var enabledModes

    property int selectedIndex: 0
    property int rowHeight: 56
    property int maxVisibleRows: 5
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

    implicitHeight: contentColumn.implicitHeight

    readonly property var fileSearchPaths: ShellConfig.Config.launcher.fileSearchPaths
    readonly property var emojiItems: emojiData.items

    EmojiData {
        id: emojiData
        active: root.open && root.mode === "emoji"
    }
    readonly property var applicationItems: root.buildApplicationItems()
    readonly property string launcherConfigDir: ShellConfig.Config.launcher.configDir
    readonly property string fileWhitelistPath: `${root.launcherConfigDir}/whitelist.txt`
    readonly property string fileBlacklistPath: `${root.launcherConfigDir}/blacklist.txt`
    readonly property var sourceItemsByMode: ({
            applications: root.applicationItems,
            files: root.fileItems,
            emoji: root.emojiItems,
            clipboard: root.clipboardItems
        })
    readonly property var sourceItems: root.enabledModes.includes(root.mode) ? root.sourceItemsByMode[root.mode] : []
    readonly property var filteredItems: root.filterItems()
    readonly property int resultsHeight: root.maxVisibleRows * root.rowHeight + Math.max(0, root.maxVisibleRows - 1) * Theme.panelItemGap
    readonly property string placeholder: root.mode === "applications" ? "Launch an application" : (root.mode === "emoji" ? "Search emoji" : (root.mode === "files" ? "Search files" : "Search copied text"))

    signal requestClose
    signal requestModeCycle(int direction)
    signal modeRequested(string mode)

    onOpenChanged: {
        if (!root.open) {
            fileSearchTimer.stop();
            root.fileSearchQueued = false;
            root.fileSearchLoading = false;
            return;
        }

        searchBox.text = "";
        root.selectedIndex = 0;
        root.selectedFileDir = root.mode === "files" ? root.initialFileDirectory() : "";
        root.refreshMode();
        root.forceActiveFocus();
        results.resetViewport();
        Qt.callLater(() => searchBox.forceInputFocus());
    }

    onModeChanged: {
        fileSearchTimer.stop();
        if (root.mode !== "files") {
            root.fileSearchQueued = false;
            root.fileSearchLoading = false;
        }
        root.selectedIndex = 0;
        root.selectedFileDir = root.mode === "files" ? root.initialFileDirectory() : "";
        if (root.mode === "files")
            root.fileItems = [];
        searchBox.text = "";
        root.refreshMode();
        results.resetViewport();
        Qt.callLater(() => searchBox.forceInputFocus());
    }

    onFilteredItemsChanged: root.clampSelection()

    function buildApplicationItems() {
        return Array.from(DesktopEntries.applications.values).map(entry => {
            const subtitle = entry.genericName.length > 0 ? entry.genericName : (entry.comment.length > 0 ? entry.comment : entry.id);
            const keywords = entry.keywords.join(" ");
            const icon = entry.icon.length > 0 ? Quickshell.iconPath(entry.icon, true) : "";

            return {
                kind: "application",
                title: entry.name,
                subtitle: subtitle,
                icon: icon,
                entry: entry,
                search: `${entry.name} ${subtitle} ${entry.id} ${keywords}`.toLowerCase()
            };
        }).sort((left, right) => left.title.localeCompare(right.title));
    }

    /** Rank app names before keyword matches while preserving other modes' order. */
    function filterItems() {
        return Search.filterItems(root.sourceItems, searchBox.text, root.mode === "applications");
    }

    function initialFileDirectory() {
        return root.fileSearchPaths.length === 1 ? root.fileSearchPaths[0] : "";
    }

    function currentFileRequest() {
        const query = searchBox.text.trim();
        return {
            query: query,
            directory: root.selectedFileDir,
            key: `${root.selectedFileDir}\u0000${query}`
        };
    }

    function refreshMode() {
        if (root.open && root.mode === "clipboard")
            root.refreshClipboard();
        if (root.open && root.mode === "files")
            root.refreshFiles();
    }

    function clampSelection() {
        if (root.filteredItems.length === 0) {
            root.selectedIndex = 0;
            return;
        }

        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.filteredItems.length - 1));
    }

    function moveSelection(delta) {
        if (root.filteredItems.length === 0)
            return;

        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, root.filteredItems.length - 1));
        results.ensureIndexVisible(root.selectedIndex);
    }

    function selectItem(item) {
        if (!item)
            return;
        if ((root.mode === "files" && root.fileSearchLoading) || (root.mode === "clipboard" && root.clipboardLoading))
            return;

        if (item.kind === "application") {
            item.entry.execute();
        } else if (item.kind === "emoji") {
            copyProcess.exec(["wl-copy", item.value]);
        } else if (item.kind === "directory") {
            root.selectedFileDir = item.path;
            searchBox.text = "";
            root.selectedIndex = 0;
            root.refreshFiles();
            searchBox.forceInputFocus();
            return;
        } else if (item.kind === "file") {
            fileOpenProcess.exec(["xdg-open", item.path]);
        } else if (item.kind === "clipboard") {
            copyProcess.exec({
                command: ["sh", "-c", "printf %s \"$CLIPHIST_ENTRY\" | cliphist decode | wl-copy"],
                environment: ({
                        CLIPHIST_ENTRY: item.raw
                    })
            });
        }

        root.requestClose();
    }

    function chooseMode(mode) {
        if (mode !== root.mode)
            root.modeRequested(mode);
    }

    function selectedItem() {
        return root.filteredItems[root.selectedIndex] ?? null;
    }

    function parseClipboardItems(text) {
        return text.split("\n").filter(line => line.length > 0).slice(0, 20).map(line => {
            const tabIndex = line.indexOf("\t");
            const label = tabIndex >= 0 ? line.slice(tabIndex + 1) : line;
            const title = label.replace(/\s+/g, " ").trim();

            return {
                kind: "clipboard",
                title: title.length > 0 ? title : "Copied item",
                subtitle: "Copy item",
                raw: line,
                search: title.toLowerCase()
            };
        });
    }

    function parseFileItems(text) {
        return text.split("\0").filter(line => line.startsWith("directory\t") || line.startsWith("file\t")).map(path => {
            const tabIndex = path.indexOf("\t");
            const kind = path.slice(0, tabIndex);
            path = path.slice(tabIndex + 1);
            const slash = path.lastIndexOf("/");
            const title = slash >= 0 ? path.slice(slash + 1) : path;
            const directory = slash >= 0 ? path.slice(0, slash) : "";
            const homePrefix = `${Quickshell.env("HOME")}/`;
            const subtitle = directory.startsWith(homePrefix) ? `~/${directory.slice(homePrefix.length)}` : directory;

            return {
                kind: kind,
                title: title.length > 0 ? title : path,
                subtitle: kind === "directory" ? "Select folder" : subtitle,
                path: path,
                search: `${title} ${subtitle}`.toLowerCase()
            };
        });
    }

    function refreshFiles() {
        if (!root.open || root.mode !== "files")
            return;

        root.fileSearchLoading = true;
        fileSearchTimer.restart();
    }

    function startFileSearch() {
        if (!root.open || root.mode !== "files")
            return;
        if (fileSearchProcess.running) {
            root.fileSearchQueued = true;
            return;
        }

        const request = root.currentFileRequest();
        root.activeFileRequest = request;
        root.fileSearchLoading = true;
        root.fileSearchError = "";
        fileSearchProcess.exec({
            command: ["bash", "-c", fileSearchCommand.text],
            environment: ({
                    FILE_QUERY: request.query,
                    FILE_DIR: request.directory,
                    FILE_WHITELIST: root.fileWhitelistPath,
                    FILE_BLACKLIST: root.fileBlacklistPath
                })
        });
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

    function emptyStateText() {
        if (root.mode === "files") {
            if (root.fileSearchLoading)
                return "Searching files...";
            if (root.fileSearchError.length > 0)
                return root.fileSearchError;
            if (root.fileSearchPaths.length === 0)
                return "No file locations configured";
            return "No matching files";
        }
        if (root.mode === "clipboard") {
            if (root.clipboardLoading)
                return "Loading clipboard...";
            if (root.clipboardError.length > 0)
                return root.clipboardError;
            return "No copied items";
        }
        return "No matches";
    }

    function copySelectedItem() {
        return root.copyItem(root.selectedItem());
    }

    function copyItem(item) {

        if (!item || !["file", "emoji", "clipboard"].includes(item.kind))
            return false;
        if ((root.mode === "files" && root.fileSearchLoading) || (root.mode === "clipboard" && root.clipboardLoading))
            return false;

        if (item.kind === "file") {
            const uri = `file://${encodeURIComponent(item.path).replace(/%2F/gi, "/")}`;
            copyProcess.exec(["wl-copy", "--type", "text/uri-list", `${uri}\n`]);
        } else if (item.kind === "emoji") {
            copyProcess.exec(["wl-copy", item.value]);
        } else {
            copyProcess.exec({
                command: ["sh", "-c", "printf %s \"$CLIPHIST_ENTRY\" | cliphist decode | wl-copy"],
                environment: ({
                        CLIPHIST_ENTRY: item.raw
                    })
            });
        }

        root.requestClose();
        return true;
    }

    function handleKey(event) {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_J) {
            root.moveSelection(1);
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
            root.moveSelection(-1);
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C && !searchBox.hasSelection && root.copySelectedItem()) {
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.requestClose();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.requestModeCycle(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.selectItem(root.selectedItem());
            event.accepted = true;
        }
    }

    Process {
        id: clipboardListProcess

        stdout: StdioCollector {
            id: clipboardOutput
        }
        stderr: StdioCollector {
            id: clipboardErrorOutput
        }
        onExited: (exitCode, exitStatus) => {
            const hasQueuedRequest = root.clipboardQueued;
            root.clipboardLoading = hasQueuedRequest;
            if (!hasQueuedRequest && root.open && root.mode === "clipboard") {
                if (exitCode === 0)
                    root.clipboardItems = root.parseClipboardItems(clipboardOutput.text);
                else
                    root.clipboardError = clipboardErrorOutput.text.trim() || "Clipboard history unavailable";
            }
            if (root.clipboardQueued) {
                root.clipboardQueued = false;
                if (root.open && root.mode === "clipboard")
                    Qt.callLater(() => root.refreshClipboard());
                else
                    root.clipboardLoading = false;
            }
        }
    }

    Process {
        id: copyProcess
    }

    Process {
        id: fileOpenProcess
    }

    Timer {
        id: fileSearchTimer

        interval: 120
        onTriggered: root.startFileSearch()
    }

    QtObject {
        id: fileSearchCommand

        readonly property string text: "\nquery=$FILE_QUERY\nselected_dir=$FILE_DIR\nwhitelist=$FILE_WHITELIST\nblacklist=$FILE_BLACKLIST\nhome=$HOME\ndirs=()\nexcludes=()\nwhile IFS= read -r line || [ -n \"$line\" ]; do\n  [ -z \"$line\" ] && continue\n  case \"$line\" in\n    /*) dir=$line ;;\n    ~/*) dir=$home/${line#~/} ;;\n    *) dir=$home/$line ;;\n  esac\n  [ -d \"$dir\" ] && dirs+=(\"$dir\")\ndone < \"$whitelist\"\nif [ -z \"$selected_dir\" ]; then\n  [ ${#dirs[@]} -eq 0 ] && exit 0\n  printf 'directory\\t%s\\0' \"${dirs[@]}\" | fzf --read0 --print0 --filter \"$query\"\n  exit 0\nfi\nwhile IFS= read -r line || [ -n \"$line\" ]; do\n  [ -z \"$line\" ] && continue\n  excludes+=(--exclude \"$line\")\ndone < \"$blacklist\"\nfd --type f --color never --absolute-path --print0 \"${excludes[@]}\" . \"$selected_dir\" 2>/dev/null | fzf --read0 --print0 --filter \"$query\" | { count=0; while IFS= read -r -d '' path; do\n  printf 'file\\t%s\\0' \"$path\"\n  count=$((count + 1))\n  [ \"$count\" -lt 80 ] || break\ndone; }\n"
    }

    Process {
        id: fileSearchProcess

        stdout: StdioCollector {
            id: fileSearchOutput
        }
        stderr: StdioCollector {
            id: fileSearchErrorOutput
        }
        onExited: (exitCode, exitStatus) => {
            const request = root.activeFileRequest;
            const hasQueuedRequest = root.fileSearchQueued && root.open && root.mode === "files";
            root.activeFileRequest = null;
            root.fileSearchLoading = hasQueuedRequest;
            if (!hasQueuedRequest && request !== null && request.key === root.currentFileRequest().key && root.open && root.mode === "files") {
                if (exitCode === 0)
                    root.fileItems = root.parseFileItems(fileSearchOutput.text);
                else
                    root.fileSearchError = fileSearchErrorOutput.text.trim() || "File search unavailable";
            }
            if (root.fileSearchQueued) {
                root.fileSearchQueued = false;
                if (root.open && root.mode === "files")
                    Qt.callLater(() => root.startFileSearch());
                else
                    root.fileSearchLoading = false;
            }
        }
    }

    Column {
        id: contentColumn

        anchors.fill: parent
        spacing: Theme.panelItemGap

        LauncherSearchBox {
            id: searchBox

            width: parent.width
            open: root.open
            placeholder: root.placeholder
            onTextChanged: {
                root.selectedIndex = 0;
                results.resetViewport();
                root.refreshFiles();
            }
            onKeyPressed: event => root.handleKey(event)
        }

        Item {
            id: resultsPanel

            width: parent.width
            height: root.resultsHeight + Theme.gap * 2

            LauncherResults {
                id: results

                anchors {
                    fill: parent
                    topMargin: Theme.gap
                    bottomMargin: Theme.gap
                }

                items: root.filteredItems
                selectedIndex: root.selectedIndex
                rowHeight: root.rowHeight
                emptyText: root.emptyStateText()

                onActivated: (index, item) => {
                    root.selectedIndex = index;
                    root.selectItem(item);
                }
                onCopyRequested: (index, item) => {
                    root.selectedIndex = index;
                    root.copyItem(item);
                }
                onHighlighted: index => root.selectedIndex = index
            }
        }

        LauncherModeTabs {
            width: parent.width
            mode: root.mode
            enabledModes: root.enabledModes
            onModeRequested: mode => root.chooseMode(mode)
        }

    }
}
