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
    property string fallbackIcon: ""

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

        Repeater {
            model: menuOpener.children

            PanelActionRow {
                required property var modelData

                Layout.fillWidth: true
                visible: !modelData.isSeparator && modelData.text.length > 0
                enabled: modelData.enabled
                label: modelData.text
                icon: root.entryIcon(modelData)
                iconSource: modelData.buttonType === QsMenuButtonType.None ? modelData.icon : ""
                showTrailing: modelData.hasChildren
                onClicked: {
                    if (modelData.hasChildren) {
                        root.openSubmenu(modelData);
                        return;
                    }

                    modelData.triggered();
                    root.activated();
                }
            }
        }
    }
}
