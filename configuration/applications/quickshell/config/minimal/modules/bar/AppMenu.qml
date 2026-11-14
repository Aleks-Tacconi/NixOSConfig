pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../.." as ShellConfig
import "../../theme"
import "../frame" as Frame

/**
 * Top-bar application identity pill and action menu popup for the focused window.
 */
Item {
    id: root

    required property var popupScreen
    property var parentWindow: null
    property real maxWidth: 340
    property real maxPopupDepth: Math.max(0, Math.min(520, (root.popupScreen?.height ?? 900) - Theme.barHeight - Theme.popupGap - Theme.gap * 6))
    property real popupLeftMargin: Theme.gap * 2
    property bool actionsOpen: false

    visible: ShellConfig.Config.appMenu.enable && AppMenuService.toplevel !== null && root.maxWidth > 0
    width: root.visible ? Math.min(root.maxWidth, identityButton.width) : 0
    height: Theme.barHeight
    clip: false

    Connections {
        target: AppMenuService

        function onToplevelChanged() {
            root.closePopup();
        }
    }

    function togglePopup() {
        if (root.actionsOpen) {
            root.closePopup();
            return;
        }
        AppMenuService.ensureResolved();
        popupContent.resetMenu();
        root.actionsOpen = true;
    }

    function closePopup() {
        root.actionsOpen = false;
    }

    Frame.BarPillButton {
        id: identityButton

        width: Math.min(root.maxWidth, 148, identityRow.implicitWidth)
        height: parent.height
        pillLeftMargin: -Theme.gap * 2
        pillRightMargin: -Theme.gap * 2
        active: root.actionsOpen
        enabled: AppMenuService.toplevel !== null
        onClicked: root.togglePopup()

        Row {
            id: identityRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.gap * 2

            IconImage {
                visible: AppMenuService.iconSource.length > 0 && identityButton.width >= 16
                width: 16
                height: 16
                source: AppMenuService.iconSource
            }

            Text {
                width: Math.max(0, Math.min(116, implicitWidth, identityButton.width - (AppMenuService.iconSource.length > 0 ? 16 + identityRow.spacing : 0)))
                color: Theme.red
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.weight: Theme.emphasisWeight
                text: AppMenuService.appName
            }
        }
    }

    Frame.BarPopupWindow {
        id: actionsWindow

        popupScreen: root.popupScreen
        requestedOpen: root.actionsOpen
        namespace: "quickshell:appMenuActions"
        alignEdge: "left"
        edgeMargin: Math.max(Theme.gap * 2, root.popupLeftMargin)
        panelWidth: 280
        panelDepth: popupContent.desiredDepth
        duration: 0
        autoClose: false
        clickDismiss: true
        contentPadding: 0
        activatorMouseArea: identityButton.mouseArea
        hoverBridgeActivator: identityButton
        onDismissRequested: root.closePopup()

        AppMenuPopup {
            id: popupContent

            anchors.fill: parent
            maxPopupDepth: root.maxPopupDepth
            onDismissRequested: root.closePopup()
        }
    }
}
