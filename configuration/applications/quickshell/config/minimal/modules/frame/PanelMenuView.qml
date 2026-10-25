pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

/**
 * In-panel navigation for native DBus menu trees.
 */
Item {
    id: root

    property var menu: null
    property var menuStack: []
    property bool showRootBack: false
    property string rootBackLabel: "Back"
    property string fallbackIcon: ""

    readonly property var currentMenu: root.menuStack.length > 0
        ? root.menuStack[root.menuStack.length - 1]
        : root.menu
    readonly property bool atRoot: root.menuStack.length === 0

    signal activated
    signal rootBackRequested

    implicitHeight: menuContent.implicitHeight

    onMenuChanged: root.reset()

    function reset() {
        root.menuStack = [];
    }

    function openSubmenu(entry) {
        root.menuStack = root.menuStack.concat([entry]);
    }

    function goBack() {
        if (root.menuStack.length === 0) {
            root.rootBackRequested();
            return;
        }

        root.menuStack = root.menuStack.slice(0, -1);
    }

    function cleanText(text) {
        if (!text)
            return "";
        return String(text).replace(/&&/g, "&").replace(/&/g, "").replace(/^_/, "").replace(/([^\w])_/, "$1");
    }

    function entryIcon(entry) {
        if (entry.buttonType === QsMenuButtonType.CheckBox)
            return entry.checkState === Qt.Checked ? "✓" : "□";
        if (entry.buttonType === QsMenuButtonType.RadioButton)
            return entry.checkState === Qt.Checked ? "●" : "○";

        return root.fallbackIcon;
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.currentMenu
    }

    ColumnLayout {
        id: menuContent

        width: parent.width
        spacing: Theme.panelItemGap

        PanelActionRow {
            visible: root.showRootBack || !root.atRoot
            Layout.fillWidth: true
            label: root.atRoot ? root.rootBackLabel : "Back"
            icon: "‹"
            showTrailing: false
            onClicked: root.goBack()
        }

        Rectangle {
            visible: root.showRootBack || !root.atRoot
            Layout.fillWidth: true
            height: 1
            color: Theme.popupBorder
        }

        Repeater {
            model: menuOpener.children

            Item {
                id: menuItem
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: menuItem.modelData.isSeparator ? 9 : (menuItem.modelData.text.length > 0 ? actionRow.implicitHeight : 0)
                implicitHeight: Layout.preferredHeight
                visible: menuItem.modelData.isSeparator || menuItem.modelData.text.length > 0

                Rectangle {
                    visible: menuItem.modelData.isSeparator
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.gap
                        rightMargin: Theme.gap
                    }
                    height: 1
                    color: Theme.popupBorder
                }

                PanelActionRow {
                    id: actionRow
                    anchors.fill: parent
                    visible: !menuItem.modelData.isSeparator && menuItem.modelData.text.length > 0
                    enabled: menuItem.modelData.enabled
                    label: root.cleanText(menuItem.modelData.text)
                    icon: root.entryIcon(menuItem.modelData)
                    iconSource: menuItem.modelData.buttonType === QsMenuButtonType.None ? menuItem.modelData.icon : ""
                    showTrailing: menuItem.modelData.hasChildren
                    onClicked: {
                        if (menuItem.modelData.hasChildren) {
                            root.openSubmenu(menuItem.modelData);
                            return;
                        }

                        menuItem.modelData.triggered();
                        root.activated();
                    }
                }
            }
        }
    }
}
