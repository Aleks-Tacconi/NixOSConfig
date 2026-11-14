pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"

/**
 * Shared top-bar popup window wrapping a PulloutPanel and optional hover bridge.
 */
PanelWindow {
    id: root

    default property alias content: contentContainer.data

    required property var popupScreen
    required property bool requestedOpen
    property bool forceClose: false
    property string namespace: "quickshell:popup"
    property string alignEdge: "right"
    property real edgeMargin: Theme.gap * 2
    property real topMargin: Theme.barHeight + Theme.popupGap
    property real panelWidth: 360
    property real panelDepth: 360
    property int duration: 180
    property int closeDelay: Theme.popupDismissDelay
    property int hoverLeaseDuration: 700
    property bool autoClose: false
    property bool clickDismiss: true
    property var activatorMouseArea: null
    property Item hoverBridgeActivator: null
    property real hoverBridgeX: 0
    property real contentPadding: Theme.panelPadding

    readonly property bool hasBridge: root.hoverBridgeActivator !== null
    readonly property alias progress: pulloutPanel.progress
    readonly property alias effectiveOpen: pulloutPanel.effectiveOpen

    signal dismissRequested

    screen: root.popupScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: (!root.forceClose && root.requestedOpen) || pulloutPanel.progress > 0
    implicitWidth: root.hasBridge
        ? Math.max(pulloutPanel.length + pulloutPanel.curveRadius, hoverBridge.x + hoverBridge.width)
        : pulloutPanel.length + pulloutPanel.curveRadius
    implicitHeight: (root.hasBridge ? root.topMargin : 0) + pulloutPanel.depth + pulloutPanel.curveRadius

    mask: Region {
        Region {
            item: pulloutPanel
        }
        Region {
            item: root.hasBridge ? hoverBridge : null
        }
    }

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: (!root.forceClose && root.requestedOpen && root.clickDismiss)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        top: true
        left: root.alignEdge === "left"
        right: root.alignEdge !== "left"
    }

    // qmllint disable unqualified unresolved-type
    margins {
        top: root.hasBridge ? 0 : root.topMargin
        left: root.alignEdge === "left" ? root.edgeMargin : 0
        right: root.alignEdge !== "left" ? root.edgeMargin : 0
    }
    // qmllint enable unqualified unresolved-type

    Item {
        id: popupHost

        anchors.fill: parent
        visible: root.visible

        PopupHoverBridge {
            id: hoverBridge

            visible: root.hasBridge
            activator: root.hoverBridgeActivator
            x: root.hoverBridgeX
            onActivated: root.dismissRequested()
        }

        PulloutPanel {
            id: pulloutPanel

            corner: root.alignEdge === "left" ? "topLeft" : "topRight"
            requestedOpen: root.requestedOpen
            forceClose: root.forceClose
            activatorMouseArea: root.activatorMouseArea
            bridgeHovered: root.hasBridge && hoverBridge.hovered
            autoClose: root.autoClose
            clickDismiss: root.clickDismiss
            closeDelay: root.closeDelay
            hoverLeaseDuration: root.hoverLeaseDuration
            duration: root.duration
            length: root.panelWidth
            depth: root.panelDepth
            backgroundColor: Theme.panelBg
            curveRadius: Theme.panelRadius
            onDismissRequested: root.dismissRequested()

            anchors {
                top: parent.top
                topMargin: root.hasBridge ? root.topMargin : 0
                left: root.alignEdge === "left" ? parent.left : undefined
                right: root.alignEdge !== "left" ? parent.right : undefined
            }

            Item {
                id: contentContainer

                anchors {
                    fill: parent
                    margins: root.contentPadding
                }
                clip: true
            }
        }
    }
}
