pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

/** In-panel navigation for native DBus menu trees with inline expandable submenus. */
Item {
    id: root

    property var menu: null
    property var menuStack: []
    property var expandedEntry: null
    property bool showRootBack: false
    property string rootBackLabel: "Back"
    property string fallbackIcon: ""

    readonly property var currentMenu: root.menuStack.length > 0 ? root.menuStack[root.menuStack.length - 1] : root.menu
    readonly property bool atRoot: root.menuStack.length === 0

    signal activated
    signal rootBackRequested

    implicitHeight: menuContent.implicitHeight
    onMenuChanged: root.reset()

    component MenuEntryItem: Item {
        id: entryItem

        required property var entry
        required property bool showRow
        property bool expanded: false
        property bool reserveIconSpace: false
        property real separatorHeight: 5
        signal triggered

        Layout.fillWidth: true
        Layout.preferredHeight: entryItem.entry.isSeparator ? entryItem.separatorHeight : rowButton.implicitHeight
        implicitHeight: Layout.preferredHeight
        visible: entryItem.showRow

        Rectangle {
            visible: entryItem.entry.isSeparator
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.gap; rightMargin: Theme.gap }
            height: 1
            color: Theme.popupBorder
        }

        PanelActionRow {
            id: rowButton

            anchors.fill: parent
            visible: !entryItem.entry.isSeparator && entryItem.entry.text.length > 0
            enabled: entryItem.entry.enabled
            active: entryItem.expanded
                || (entryItem.entry.buttonType !== QsMenuButtonType.None && entryItem.entry.checkState === Qt.Checked)
            label: root.cleanText(entryItem.entry.text)
            icon: root.entryIcon(entryItem.entry)
            iconSource: root.resolveIcon(entryItem.entry)
            monochromeIcon: true
            reserveIconSpace: entryItem.reserveIconSpace
            showTrailing: entryItem.entry.hasChildren
            trailingFontFamily: Theme.iconFontFamily
            trailingText: entryItem.expanded ? "󰅀" : "󰅂"
            onClicked: entryItem.triggered()
        }
    }

    function closeEntry(entry) { if (entry) entry.closed(); }
    function openEntry(entry) { entry.opened(); if (typeof entry.updateLayout === "function") entry.updateLayout(); }

    function reset() {
        root.closeEntry(root.expandedEntry);
        root.expandedEntry = null;
        root.menuStack = [];
    }

    function activateEntry(entry, toggleInline) {
        if (!entry.hasChildren) {
            entry.triggered();
            root.activated();
            return;
        }
        if (!toggleInline) {
            root.openSubmenu(entry);
            return;
        }
        if (root.expandedEntry === entry) {
            root.closeEntry(entry);
            root.expandedEntry = null;
            return;
        }
        root.closeEntry(root.expandedEntry);
        root.openEntry(entry);
        root.expandedEntry = entry;
    }

    function openSubmenu(entry) {
        root.closeEntry(root.expandedEntry);
        root.expandedEntry = null;
        root.openEntry(entry);
        root.menuStack = root.menuStack.concat([entry]);
    }

    function goBack() {
        root.closeEntry(root.expandedEntry);
        root.expandedEntry = null;
        if (root.menuStack.length === 0) {
            root.rootBackRequested();
            return;
        }
        root.closeEntry(root.menuStack[root.menuStack.length - 1]);
        root.menuStack = root.menuStack.slice(0, -1);
    }

    function cleanText(text) {
        return text ? String(text).replace(/&&/g, "&").replace(/&/g, "").replace(/^_/, "").replace(/([^\w])_/, "$1") : "";
    }

    function entryIcon(entry) {
        if (entry.buttonType === QsMenuButtonType.CheckBox)
            return entry.checkState === Qt.Checked ? "󰄲" : "󰄱";
        if (entry.buttonType === QsMenuButtonType.RadioButton)
            return entry.checkState === Qt.Checked ? "󰪥" : "󰝦";
        return root.fallbackIcon;
    }

    function resolveIcon(entry) {
        if (entry.buttonType !== QsMenuButtonType.None)
            return "";
        const value = String(entry.icon ?? "");
        if (value.length === 0)
            return "";
        if (value.startsWith("image://") || value.startsWith("file://") || value.startsWith("qrc:"))
            return value;
        return value.startsWith("/") ? "file://" + value : Quickshell.iconPath(value, true);
    }

    function menuHasIcons(entries) {
        return root.fallbackIcon.length > 0 || entries.some(entry =>
            !entry.isSeparator && (entry.buttonType !== QsMenuButtonType.None || String(entry.icon ?? "").length > 0));
    }

    /** Show a separator only between real items, collapsing runs and edges. */
    function shouldShowEntry(entries, index, entry) {
        if (!entry.isSeparator)
            return entry.text.length > 0;
        const isItem = item => !item.isSeparator && item.text.length > 0;
        const previous = entries.slice(0, index).filter(item => item.isSeparator || isItem(item)).pop();
        return previous !== undefined && isItem(previous) && entries.slice(index + 1).some(isItem);
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenu
    }

    ColumnLayout {
        id: menuContent

        width: parent.width
        spacing: Theme.gap / 2

        PanelActionRow {
            visible: root.showRootBack || !root.atRoot
            Layout.fillWidth: true
            label: root.atRoot ? root.rootBackLabel : root.cleanText(root.currentMenu?.text) || "Back"
            icon: "‹"
            active: !root.atRoot
            showTrailing: false
            onClicked: root.goBack()
        }

        Rectangle {
            visible: root.showRootBack || !root.atRoot
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.popupBorder
        }

        Repeater {
            model: menuOpener.children

            ColumnLayout {
                id: menuItem

                required property var modelData
                required property int index
                readonly property bool isExpanded: root.expandedEntry === menuItem.modelData

                Layout.fillWidth: true
                spacing: Theme.gap
                visible: root.shouldShowEntry(menuOpener.children.values, menuItem.index, menuItem.modelData)

                MenuEntryItem {
                    entry: menuItem.modelData
                    showRow: true
                    expanded: menuItem.isExpanded
                    reserveIconSpace: root.menuHasIcons(menuOpener.children.values)
                    onTriggered: root.activateEntry(menuItem.modelData, true)
                }

                RowLayout {
                    visible: menuItem.isExpanded
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.gap * 2
                    spacing: Theme.gap * 1.5

                    QsMenuOpener {
                        id: subOpener
                        menu: menuItem.isExpanded ? menuItem.modelData : null
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.fillHeight: true
                        radius: 1
                        color: Theme.popupBorder
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.gap / 2

                        Repeater {
                            model: subOpener.children

                            MenuEntryItem {
                                id: subItem
                                required property var modelData
                                required property int index
                                entry: subItem.modelData
                                separatorHeight: 5
                                reserveIconSpace: root.menuHasIcons(subOpener.children.values)
                                showRow: root.shouldShowEntry(subOpener.children.values, subItem.index, subItem.modelData)
                                onTriggered: root.activateEntry(subItem.modelData, false)
                            }
                        }
                    }
                }
            }
        }
    }
}
