pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"

/**
 * Rich notification card with sender imagery, urgency, and actions.
 */
Rectangle {
    id: root

    required property var notification
    property bool toast: false
    property real cardPadding: root.toast ? Theme.gap * 3 : Theme.gap * 1.5

    signal dismissRequested(var notification)
    signal actionRequested(var notification, var action)
    signal interactionChanged(bool interacting)

    readonly property var actions: root.notification?.actions ?? []
    readonly property bool critical: (root.notification?.urgency ?? 1) === 2
    readonly property bool lowPriority: (root.notification?.urgency ?? 1) === 0
    readonly property string appIconSource: {
        const icon = root.notification?.appIcon ?? "";
        return icon.length > 0 ? Quickshell.iconPath(icon, true) : "";
    }
    readonly property bool interacting: hoverHandler.hovered

    width: parent?.width ?? 0
    implicitHeight: Math.max(root.toast ? 74 : 58, cardContent.implicitHeight + root.cardPadding * 2)
    height: implicitHeight
    radius: root.toast ? 0 : Theme.surfaceRadius
    color: root.toast ? "transparent" : (root.interacting ? Theme.panelSurfaceHover : "transparent")
    opacity: root.lowPriority ? 0.82 : 1
    clip: true
    border.width: 0

    onInteractingChanged: root.interactionChanged(root.interacting)

    HoverHandler {
        id: hoverHandler
    }

    Column {
        id: cardContent

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: root.cardPadding
            rightMargin: root.cardPadding
            topMargin: root.cardPadding
        }
        spacing: Theme.gap * 2

        Row {
            width: parent.width
            spacing: Theme.gap * 2

            Rectangle {
                width: 42
                height: 42
                radius: Theme.surfaceRadius
                color: "transparent"
                clip: true

                Image {
                    id: notificationImage

                    anchors.fill: parent
                    source: root.notification?.image ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    source: root.appIconSource
                    visible: notificationImage.status !== Image.Ready && root.appIconSource.length > 0
                }

                Text {
                    anchors.centerIn: parent
                    visible: notificationImage.status !== Image.Ready && root.appIconSource.length === 0
                    text: (root.notification?.appName || "A").slice(0, 1).toUpperCase()
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    font.bold: true
                }
            }

            Column {
                width: parent.width - 42 - closeButton.width - parent.spacing * 2
                spacing: Theme.gap * 0.6

                Text {
                    width: parent.width
                    text: root.critical ? `${root.notification?.appName || "App"} · Critical` : (root.notification?.appName || "App")
                    color: root.critical ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    font.bold: root.critical
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    width: parent.width
                    text: root.notification?.summary || "Notification"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                    font.bold: true
                    maximumLineCount: root.toast ? 1 : 2
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    width: parent.width
                    visible: (root.notification?.body || "").length > 0
                    text: root.notification?.body || ""
                    color: Theme.fg
                    opacity: 0.8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    maximumLineCount: root.toast ? 2 : 4
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            Rectangle {
                id: closeButton

                width: 32
                height: 32
                radius: Theme.surfaceRadius
                color: closeMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeMouse.containsMouse ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelBodySize
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.dismissRequested(root.notification)
                }
            }
        }

        Flow {
            id: actionFlow

            width: parent.width
            visible: root.actions.length > 0
            height: visible ? implicitHeight : 0
            spacing: Theme.gap

            Repeater {
                model: root.actions

                NotificationActionButton {
                    required property var modelData

                    width: Math.min(actionFlow.width, implicitWidth)
                    action: modelData
                    primary: modelData.identifier === "default"
                    onInvoked: action => root.actionRequested(root.notification, action)
                }
            }
        }
    }
}
