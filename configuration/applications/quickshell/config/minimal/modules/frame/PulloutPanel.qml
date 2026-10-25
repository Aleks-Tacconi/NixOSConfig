pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"

/**
 * Shared popup surface with explicit dismissal or hover-preview behavior.
 */
FocusScope {
    id: root

    default property alias content: contentHost.data

    property string edge: "top"
    property string corner: ""
    property bool requestedOpen: false
    property bool forceClose: false
    property var activatorMouseArea: null
    property bool autoClose: false
    property bool dismissOnExit: root.clickDismiss
    property bool clickDismiss: false
    property int closeDelay: Theme.popupDismissDelay
    property int hoverLeaseDuration: 700
    property real length: parent ? parent.width : 0
    property real depth: 0
    property int duration: 160
    property int easingType: Easing.OutCubic
    property color backgroundColor: Theme.panelBg
    property color borderColor: Theme.bg2
    property color outerBorderColor: Theme.bg
    property color eraseColor: Theme.bg
    property real borderWidth: 5
    property real outerBorderWidth: 7
    property real curveRadius: Theme.panelRadius
    property real seamOverlap: 3
    property bool eraseBaseBorder: true
    property real progress: effectiveOpen ? 1 : 0

    Keys.onEscapePressed: event => {
        if (root.clickDismiss) {
            root.dismissRequested();
            event.accepted = true;
        }
    }

    onEffectiveOpenChanged: {
        if (root.effectiveOpen && root.clickDismiss)
            Qt.callLater(() => {
                if (root.effectiveOpen)
                    root.forceActiveFocus(Qt.PopupFocusReason);
            });
    }

    HyprlandFocusGrab {
        active: root.clickDismiss && root.effectiveOpen
        windows: root.activatorMouseArea
            ? [root.QsWindow.window, root.activatorMouseArea.QsWindow.window]
            : [root.QsWindow.window]
        onCleared: {
            if (root.clickDismiss && root.effectiveOpen && !root.interactionHovered)
                root.dismissRequested();
        }
    }

    signal dismissRequested

    readonly property bool panelHovered: panelHover.hovered
    readonly property bool activatorHovered: root.activatorMouseArea?.containsMouse ?? false
    readonly property bool interactionHovered: root.panelHovered || root.activatorHovered
    readonly property bool effectiveOpen: !forceClose && (autoClose ? heldOpen : requestedOpen)

    property bool heldOpen: requestedOpen

    width: length
    height: depth
    visible: effectiveOpen || progress > 0
    opacity: progress

    onRequestedOpenChanged: {
        if (!root.autoClose) {
            root.heldOpen = root.requestedOpen;

            if (!root.requestedOpen)
                closeTimer.stop();

            return;
        }

        if (root.requestedOpen)
            root.openFromHover();
        else
            root.closeWhenReady();
    }

    onAutoCloseChanged: root.heldOpen = root.requestedOpen
    onActivatorMouseAreaChanged: root.updateActivatorHover()
    onForceCloseChanged: {
        if (root.forceClose)
            root.heldOpen = false;
    }

    function openFromHover() {
        if (!root.requestedOpen) {
            root.heldOpen = false;
            return;
        }

        root.holdOpen();
    }

    function holdOpen() {
        root.heldOpen = true;
        closeTimer.stop();
        hoverLease.restart();
    }

    function closeWhenReady() {
        if (root.autoClose) {
            closeTimer.restart();
            return;
        }

        if (root.dismissOnExit && root.requestedOpen)
            closeTimer.restart();
    }

    function refreshActivatorLease() {
        if (root.autoClose && root.heldOpen)
            hoverLease.restart();
    }

    function updateActivatorHover() {
        if ((!root.autoClose && !root.dismissOnExit) || !root.activatorMouseArea)
            return;

        if (root.activatorHovered) {
            closeTimer.stop();

            if (root.autoClose)
                root.openFromHover();

            return;
        }

        root.closeWhenReady();
    }

    Timer {
        id: closeTimer

        interval: root.closeDelay
        onTriggered: {
            if (root.interactionHovered)
                return;

            if (root.autoClose)
                root.heldOpen = false;

            if (root.dismissOnExit && root.requestedOpen)
                root.dismissRequested();
        }
    }

    Timer {
        id: hoverLease

        interval: root.hoverLeaseDuration
        onTriggered: {
            if (!root.autoClose)
                return;
            if (root.panelHovered || (root.activatorMouseArea?.containsMouse ?? false)) {
                hoverLease.restart();
                return;
            }

            root.heldOpen = false;
        }
    }

    Connections {
        target: root.activatorMouseArea
        enabled: (root.autoClose || root.dismissOnExit) && root.activatorMouseArea !== null
        ignoreUnknownSignals: true

        function onContainsMouseChanged() {
            root.updateActivatorHover();
        }

        function onPositionChanged() {
            root.refreshActivatorLease();
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: root.duration
            easing.type: root.easingType
        }
    }

    PanelSurface {
        anchors.fill: parent
        color: root.backgroundColor
        radius: root.curveRadius
    }

    Item {
        id: contentClip

        anchors.fill: parent
        clip: true
        visible: root.progress > 0

        HoverHandler {
            id: panelHover

            onHoveredChanged: {
                if (!root.autoClose && !root.dismissOnExit)
                    return;

                if (panelHover.hovered) {
                    closeTimer.stop();

                    if (root.autoClose)
                        root.holdOpen();

                    return;
                }

                root.closeWhenReady();
            }
        }

        Item {
            id: contentHost

            anchors.fill: parent
        }
    }
}
