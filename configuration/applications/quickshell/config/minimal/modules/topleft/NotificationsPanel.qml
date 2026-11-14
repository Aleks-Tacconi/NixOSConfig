pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../frame" as Frame
import "../wallpaper" as Wallpaper
import "../../theme"

/**
 * Notifications list, quick actions bar, and inline wallpaper picker panel.
 */
Item {
    id: root

    required property var notificationCenter
    property bool wallpaperPickerOpen: false
    property real panelDepth: 0

    signal closeRequested

    Wallpaper.WallpaperPicker {
        anchors.fill: parent
        visible: root.wallpaperPickerOpen
        onBackRequested: root.wallpaperPickerOpen = false
    }

    Column {
        id: notificationsContent
        visible: !root.wallpaperPickerOpen
        anchors.fill: parent
        spacing: Theme.panelSectionGap

        Item {
            id: notificationSection
            width: parent.width
            height: Math.max(0, parent.height - quickActionsSection.height - (quickActionsSection.visible ? parent.spacing : 0))
            clip: true

            Column {
                id: notificationSectionContent
                anchors { fill: parent; margins: Theme.gap }
                spacing: Theme.panelItemGap

                Item {
                    width: parent.width
                    height: 30

                    Frame.PanelSectionHeader {
                        anchors {
                            left: parent.left; right: parent.right
                            rightMargin: clearButton.visible ? clearButton.width + Theme.gap * 2 : 0
                            verticalCenter: parent.verticalCenter
                        }
                        title: "Notifications"
                        detail: ""
                    }

                    Rectangle {
                        id: clearButton
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        visible: root.notificationCenter?.hasNotifications ?? false
                        width: 68; height: 28
                        radius: Theme.surfaceRadius
                        color: clearMouse.containsMouse ? Theme.panelSurfaceHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearMouse.containsMouse ? Theme.fg : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                            font.weight: Theme.emphasisWeight
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.notificationCenter?.clearNotifications()
                        }
                    }
                }

                Item {
                    id: notificationsViewport
                    width: parent.width
                    height: Math.max(0, parent.height - 30 - parent.spacing)
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        visible: !(root.notificationCenter?.hasNotifications ?? false)
                        text: "No notifications"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                    }

                    ListView {
                        id: notificationsList
                        anchors { fill: parent; rightMargin: Theme.gap * 2 }
                        spacing: Theme.gap
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: ScriptModel { values: root.notificationCenter?.newestNotifications ?? [] }

                        delegate: NotificationCard {
                            id: notificationRow
                            required property var modelData
                            width: ListView.view.width
                            notification: notificationRow.modelData
                            onDismissRequested: notification => root.notificationCenter?.dismissNotification(notification)
                            onActionRequested: (notification, action) => root.notificationCenter?.invokeNotificationAction(notification, action)
                            onActivated: notification => {
                                if (root.notificationCenter?.activateNotification(notification))
                                    root.closeRequested();
                            }
                        }
                    }

                    Frame.PanelScrollIndicator {
                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: 1 }
                        flickable: notificationsList
                    }
                }
            }
        }

        Item {
            id: quickActionsSection
            visible: root.panelDepth >= 400
            width: parent.width
            height: visible ? quickActionsContent.implicitHeight + Theme.gap * 2 : 0

            Column {
                id: quickActionsContent
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gap }
                spacing: Theme.panelItemGap

                Frame.PanelGroupLabel { width: parent.width; title: "Quick actions" }

                Column {
                    id: actionBar
                    width: parent.width; height: implicitHeight
                    spacing: Theme.gap

                    Frame.PanelActionRow {
                        width: actionBar.width; implicitHeight: 36; showTrailing: false
                        label: "Do Not Disturb"; icon: "󰂛"
                        active: root.notificationCenter?.dndEnabled ?? false
                        detailText: active ? "On" : "Off"
                        onClicked: {
                            if (root.notificationCenter !== null)
                                root.notificationCenter.dndEnabled = !root.notificationCenter.dndEnabled;
                        }
                    }

                    Frame.PanelActionRow {
                        width: actionBar.width; implicitHeight: 36; showTrailing: false
                        label: "Pick Color"; icon: ""
                        onClicked: root.notificationCenter?.pickColor()
                    }

                    Frame.PanelActionRow {
                        width: actionBar.width; implicitHeight: 36; showTrailing: false
                        label: "Night Light"; icon: "󰖔"
                        active: root.notificationCenter?.hyprsunsetEnabled ?? false
                        enabled: !(root.notificationCenter?.hyprsunsetPending ?? false)
                        detailText: (root.notificationCenter?.hyprsunsetEnabled ?? false) ? "On" : "Off"
                        onClicked: root.notificationCenter?.toggleHyprsunset()
                    }

                    Frame.PanelActionRow {
                        width: actionBar.width; implicitHeight: 36; showTrailing: false
                        label: "Wallpapers"; icon: "󰸉"
                        onClicked: root.wallpaperPickerOpen = true
                    }

                    Frame.PanelActionRow {
                        width: actionBar.width; implicitHeight: 36; showTrailing: false
                        label: "Screenshot"; icon: ""
                        onClicked: root.notificationCenter?.takeScreenshot()
                    }
                }
            }
        }
    }
}
