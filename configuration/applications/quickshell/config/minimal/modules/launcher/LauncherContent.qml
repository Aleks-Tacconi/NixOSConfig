pragma ComponentBehavior: Bound

import QtQuick
import "search.js" as Search
import Quickshell
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
    property real rankingTime: Date.now()
    property int rowHeight: Theme.panelRowHeight + Theme.panelSectionGap
    property int maxVisibleRows: 5

    implicitHeight: contentColumn.implicitHeight

    readonly property var fileSearchPaths: ShellConfig.Config.launcher.fileSearchPaths
    readonly property var emojiItems: emojiData.items
    readonly property var applicationItems: root.buildApplicationItems()
    readonly property var sourceItemsByMode: ({
        applications: root.applicationItems,
        files: backend.fileItems,
        emoji: root.emojiItems,
        clipboard: backend.clipboardItems
    })
    readonly property var sourceItems: root.enabledModes.includes(root.mode) ? root.sourceItemsByMode[root.mode] : []
    readonly property var filteredItems: root.filterItems()
    readonly property int visibleResultRows: Math.max(1, Math.min(root.maxVisibleRows, root.filteredItems.length))
    readonly property int resultsHeight: root.visibleResultRows * root.rowHeight + Math.max(0, root.visibleResultRows - 1) * Theme.panelItemGap
    readonly property string placeholder: root.mode === "applications" ? "Launch an application"
        : (root.mode === "emoji" ? "Search emoji" : (root.mode === "files" ? "Search files" : "Search copied text"))

    signal requestClose
    signal requestModeCycle(int direction)
    signal modeRequested(string mode)

    EmojiData { id: emojiData; active: root.open && root.mode === "emoji" }
    LauncherBackend { id: backend; open: root.open; mode: root.mode; query: searchBox.text }

    onOpenChanged: {
        if (!root.open) {
            backend.stopFileSearch();
            return;
        }
        root.rankingTime = Date.now();
        searchBox.text = "";
        root.selectedIndex = 0;
        backend.selectedFileDir = root.mode === "files" ? backend.initialFileDirectory() : "";
        root.refreshMode();
        root.forceActiveFocus();
        results.resetViewport();
        Qt.callLater(() => searchBox.forceInputFocus());
    }

    onModeChanged: {
        backend.stopFileSearch();
        root.selectedIndex = 0;
        backend.selectedFileDir = root.mode === "files" ? backend.initialFileDirectory() : "";
        if (root.mode === "files")
            backend.fileItems = [];
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
                kind: "application", id: entry.id, title: entry.name, subtitle: subtitle, icon: icon, entry: entry,
                search: `${entry.name} ${subtitle} ${entry.id} ${keywords}`.toLowerCase()
            };
        }).sort((left, right) => left.title.localeCompare(right.title));
    }

    /** Rank name matches first, then favor frequent recent application launches. */
    function filterItems() {
        return Search.filterItems(root.sourceItems, searchBox.text, root.mode === "applications", LaunchHistory.apps, root.rankingTime);
    }

    function refreshMode() {
        if (root.open && root.mode === "clipboard")
            backend.refreshClipboard();
        if (root.open && root.mode === "files")
            backend.refreshFiles();
    }

    function clampSelection() {
        root.selectedIndex = root.filteredItems.length === 0 ? 0 : Math.max(0, Math.min(root.selectedIndex, root.filteredItems.length - 1));
    }

    function moveSelection(delta) {
        if (root.filteredItems.length === 0)
            return;
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, root.filteredItems.length - 1));
        results.ensureIndexVisible(root.selectedIndex);
    }

    function selectItem(item) {
        if (!item || (root.mode === "files" && backend.fileSearchLoading) || (root.mode === "clipboard" && backend.clipboardLoading))
            return;
        if (item.kind === "application") {
            item.entry.execute();
            LaunchHistory.record(item.id);
        } else if (item.kind === "emoji") {
            backend.copyText(item.value);
        } else if (item.kind === "directory") {
            backend.selectedFileDir = item.path;
            searchBox.text = "";
            root.selectedIndex = 0;
            backend.refreshFiles();
            searchBox.forceInputFocus();
            return;
        } else if (item.kind === "file") {
            backend.openFile(item.path);
        } else if (item.kind === "clipboard") {
            backend.copyClipboardEntry(item.raw);
        }
        root.requestClose();
    }

    function chooseMode(mode) { if (mode !== root.mode) root.modeRequested(mode); }
    function selectedItem() { return root.filteredItems[root.selectedIndex] ?? null; }
    function copySelectedItem() { return root.copyItem(root.selectedItem()); }

    function emptyStateText() {
        if (root.mode === "files") {
            if (backend.fileSearchLoading) return "Searching files...";
            if (backend.fileSearchError.length > 0) return backend.fileSearchError;
            return root.fileSearchPaths.length === 0 ? "No file locations configured" : "No matching files";
        }
        if (root.mode === "clipboard") {
            if (backend.clipboardLoading) return "Loading clipboard...";
            return backend.clipboardError.length > 0 ? backend.clipboardError : "No copied items";
        }
        return "No matches";
    }

    function copyItem(item) {
        if (!item || !["file", "emoji", "clipboard"].includes(item.kind))
            return false;
        if ((root.mode === "files" && backend.fileSearchLoading) || (root.mode === "clipboard" && backend.clipboardLoading))
            return false;
        if (item.kind === "file")
            backend.copyFileUri(item.path);
        else if (item.kind === "emoji")
            backend.copyText(item.value);
        else
            backend.copyClipboardEntry(item.raw);
        root.requestClose();
        return true;
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        if ((ctrl && event.key === Qt.Key_J) || event.key === Qt.Key_Down) {
            root.moveSelection(1);
            event.accepted = true;
        } else if ((ctrl && event.key === Qt.Key_K) || event.key === Qt.Key_Up) {
            root.moveSelection(-1);
            event.accepted = true;
        } else if (ctrl && event.key === Qt.Key_C && !searchBox.hasSelection && root.copySelectedItem()) {
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.requestClose();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.requestModeCycle(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.selectItem(root.selectedItem());
            event.accepted = true;
        }
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: Theme.panelItemGap

        LauncherModeHeading { width: parent.width; mode: root.mode }

        LauncherSearchBox {
            id: searchBox
            width: parent.width; open: root.open; placeholder: root.placeholder
            onTextChanged: {
                root.selectedIndex = 0;
                results.resetViewport();
                backend.refreshFiles();
            }
            onKeyPressed: event => root.handleKey(event)
        }

        Item {
            id: resultsPanel
            width: parent.width
            height: root.resultsHeight + Theme.gap * 2

            LauncherResults {
                id: results
                anchors { fill: parent; topMargin: Theme.gap; bottomMargin: Theme.gap }
                items: root.filteredItems
                selectedIndex: root.selectedIndex
                rowHeight: root.rowHeight
                emptyText: root.emptyStateText()
                onActivated: (index, item) => { root.selectedIndex = index; root.selectItem(item); }
                onCopyRequested: (index, item) => { root.selectedIndex = index; root.copyItem(item); }
                onHighlighted: index => root.selectedIndex = index
            }
        }
    }
}
