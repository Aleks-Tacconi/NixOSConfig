pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"
import "../.." as ShellConfig

/**
 * Top-left status cluster with time, notifications, and calendar preview.
 */
Item {
    id: root

    width: statusFrame.width
    height: Theme.barHeight

    property var popupScreen: null
    property var notificationCenter: null
    property bool hasNotifications: false
    property bool dndEnabled: false
    property string openPopup: ""
    property string nextCalendarItem: "No events"
    readonly property bool calendarOpen: root.openPopup === "calendar"
    readonly property bool notificationsOpen: root.openPopup === "notifications"
    readonly property string currentScreenKey: screenKey(root.popupScreen)
    readonly property bool colorPickerActive: root.notificationCenter?.colorPickerActive ?? false
    readonly property bool menuOpen: !root.colorPickerActive && (root.notificationsOpen || root.calendarOpen || notificationsPanel.progress > 0 || calendarPanel.progress > 0)
    readonly property bool ownsNotificationPopup: root.notificationCenter !== null && root.notificationCenter.notificationPopupScreenKey === root.currentScreenKey
    readonly property var activeNotification: root.notificationCenter?.activeNotification ?? null

    function notificationIcon() {
        return root.notificationCenter?.dndEnabled ? "󰂛" : "󰂚";
    }

    function screenKey(screen) {
        if (screen === null || screen === undefined)
            return "";

        return screen.name ?? `${screen.x},${screen.y}:${screen.width}x${screen.height}`;
    }

    function sectionLabel(text) {
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    function isFocusedScreen() {
        const monitor = Hyprland.monitorFor(root.popupScreen);

        return monitor?.focused ?? false;
    }

    Component.onCompleted: {
        if (root.isFocusedScreen() || (root.notificationCenter?.notificationPopupScreenKey ?? "").length === 0)
            root.notificationCenter?.setNotificationPopupScreen(root.currentScreenKey);
    }

    Component.onDestruction: {
        root.notificationCenter?.setMenuOpen(root.currentScreenKey, false);
        root.notificationCenter?.clearNotificationPopupScreen(root.currentScreenKey);
    }

    onMenuOpenChanged: {
        root.notificationCenter?.setMenuOpen(root.currentScreenKey, root.menuOpen);
    }

    onColorPickerActiveChanged: {
        if (root.colorPickerActive)
            root.openPopup = "";
    }

    function togglePopup(name) {
        root.openPopup = root.openPopup === name ? "" : name;
    }

    function closePopup(name) {
        if (root.openPopup === name)
            root.openPopup = "";
    }

    Connections {
        target: root.notificationCenter

        function onNotificationPulseChanged() {
            if (root.isFocusedScreen())
                root.notificationCenter?.setNotificationPopupScreen(root.currentScreenKey);
        }

        function onMenuActionRequested(action) {
            if (action === "close") {
                root.closePopup("notifications");
                return;
            }

            if (!root.isFocusedScreen()) {
                root.closePopup("notifications");
                return;
            }

            if (action === "toggle")
                root.togglePopup("notifications");
            else if (action === "open")
                root.openPopup = "notifications";
        }
    }

    Item {
        id: statusFrame

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: statusContent.implicitWidth
        height: statusContent.implicitHeight

        Row {
            id: statusContent

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            spacing: Theme.gap * 5 + 2

            Item {
                id: calendarSegment

                z: calendarTrigger.containsMouse ? 1 : 0
                width: calendarStatusRow.implicitWidth
                height: 28

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
                    color: calendarTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                Row {
                    id: calendarStatusRow

                    anchors.centerIn: parent
                    spacing: Theme.gap * 5 + 2

                    StatusCell {
                        icon: ""
                        label: Qt.formatDateTime(clockTimer.now, "hh:mm")
                    }

                    StatusCell {
                        icon: "󰃭"
                        label: root.notificationCenter?.calendarPreview ?? root.nextCalendarItem
                        scrollLabel: true
                        labelMaxWidth: 220
                    }
                }

                MouseArea {
                    id: calendarTrigger

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.togglePopup("calendar")
                }
            }

            Item {
                id: notificationsSegment

                z: notificationsTrigger.containsMouse ? 1 : 0
                width: notificationsStatus.width
                height: 28

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
                    color: notificationsTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                StatusCell {
                    id: notificationsStatus

                    anchors.centerIn: parent
                    icon: root.notificationIcon()
                    label: String(root.notificationCenter?.notificationCount ?? 0)
                    dotVisible: root.notificationCenter?.hasNotifications ?? false
                }

                MouseArea {
                    id: notificationsTrigger

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.togglePopup("notifications")
                }
            }
        }
    }

    Timer {
        id: clockTimer

        property date now: new Date()

        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

    PanelWindow {
        id: notificationsPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: (!root.colorPickerActive && root.notificationsOpen) || notificationsPanel.progress > 0
        implicitWidth: notificationsPanel.length + notificationsPanel.curveRadius
        implicitHeight: notificationsPanel.depth + notificationsPanel.curveRadius
        mask: Region {
            item: notificationsPopupHost
        }

        WlrLayershell.namespace: "quickshell:topLeftNotificationsPullout"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            left: Theme.gap * 2
        }

        Item {
            id: notificationsPopupHost

            anchors.fill: parent
            clip: false
            visible: notificationsPopupWindow.visible

            Frame.PulloutPanel {
                id: notificationsPanel

                corner: "topLeft"
                requestedOpen: root.notificationsOpen && !root.colorPickerActive && notificationPanel.progress <= 0
                forceClose: root.colorPickerActive
                activatorMouseArea: notificationsTrigger
                dismissOnExit: true
                onDismissRequested: root.closePopup("notifications")

                length: 430
                depth: notificationsContent.implicitHeight + 36
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    left: parent.left
                }

                Column {
                    id: notificationsContent

                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }

                    spacing: Theme.panelItemGap

                    Frame.PanelSectionHeader {
                        width: parent.width
                        title: "Quick Actions"
                    }

                    Frame.PanelDivider {
                        width: parent.width
                    }

                    Column {
                        id: actionBar

                        width: parent.width
                        height: implicitHeight
                        spacing: Theme.gap

                        ActionButton {
                            width: parent.width
                            label: root.notificationCenter?.dndEnabled ? "Do Not Disturb On" : "Do Not Disturb Off"
                            icon: "󰂛"
                            active: root.notificationCenter?.dndEnabled ?? false
                            onClicked: {
                                if (root.notificationCenter !== null)
                                    root.notificationCenter.dndEnabled = !root.notificationCenter.dndEnabled;
                            }
                        }

                        ActionButton {
                            width: parent.width
                            label: "Pick Color"
                            icon: ""
                            onClicked: root.notificationCenter?.pickColor()
                        }

                        ActionButton {
                            width: parent.width
                            label: "Night Light"
                            icon: "󰖔"
                            active: root.notificationCenter?.hyprsunsetEnabled ?? false
                            enabled: !(root.notificationCenter?.hyprsunsetPending ?? false)
                            detailText: (root.notificationCenter?.hyprsunsetEnabled ?? false) ? "On" : "Off"
                            onClicked: root.notificationCenter?.toggleHyprsunset()
                        }

                        ActionButton {
                            width: parent.width
                            label: "Screenshot"
                            icon: ""
                            onClicked: root.notificationCenter?.takeScreenshot()
                        }
                    }

                    Frame.PanelDivider {
                        width: parent.width
                    }

                    Item {
                        width: parent.width
                        height: notificationsLabel.implicitHeight

                        Text {
                            id: notificationsLabel

                            anchors.verticalCenter: parent.verticalCenter
                            text: root.sectionLabel("notifications")
                            color: Theme.red
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelTitleSize
                            font.bold: true
                        }

                        Text {
                            id: clearNotifications

                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }

                            text: "Clear"
                            color: clearMouse.containsMouse ? Theme.red : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                            font.bold: true

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

                    Rectangle {
                        width: parent.width
                        height: 260
                        color: "transparent"
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
                            anchors {
                                fill: parent
                                topMargin: 0
                                bottomMargin: 0
                            }

                            spacing: Theme.gap
                            clip: true
                            model: root.notificationCenter?.notifications ?? null

                            delegate: NotificationCard {
                                required property var modelData

                                width: ListView.view.width
                                notification: modelData
                                onDismissRequested: notification => root.notificationCenter?.dismissActiveNotification(notification)
                            }
                        }
                    }

                }
            }
        }
    }

    PanelWindow {
        id: calendarPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: (!root.colorPickerActive && root.calendarOpen) || calendarPanel.progress > 0
        implicitWidth: calendarPanel.length + calendarPanel.curveRadius
        implicitHeight: calendarPanel.depth + calendarPanel.curveRadius
        mask: Region {
            item: calendarPopupHost
        }

        WlrLayershell.namespace: "quickshell:topLeftCalendarPullout"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            left: Theme.gap * 2
        }

        Item {
            id: calendarPopupHost

            anchors.fill: parent
            clip: false
            visible: calendarPopupWindow.visible

            Frame.PulloutPanel {
                id: calendarPanel

                corner: "topLeft"
                requestedOpen: root.calendarOpen && !root.colorPickerActive
                forceClose: root.colorPickerActive
                activatorMouseArea: calendarTrigger
                dismissOnExit: true
                onDismissRequested: root.closePopup("calendar")

                length: 430
                depth: calendarContent.implicitHeight + 36
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    left: parent.left
                }

                Column {
                    id: calendarContent

                    anchors {
                        fill: parent
                        topMargin: Theme.panelPadding
                        leftMargin: Theme.panelPadding
                        rightMargin: Theme.panelPadding
                        bottomMargin: Theme.panelPadding
                    }

                    spacing: Theme.panelItemGap

                    Frame.PanelSectionHeader {
                        width: parent.width
                        title: root.sectionLabel("google calendar")
                        detail: Qt.formatDateTime(clockTimer.now, "hh:mm")
                    }

                    Rectangle {
                        width: parent.width
                        height: 430
                        color: "transparent"
                        clip: true

                        CalendarMonth {
                            anchors {
                                fill: parent
                                margins: Theme.gap
                            }

                            events: root.notificationCenter?.calendarEvents ?? []
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: notificationPopupWindow

        screen: root.popupScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: root.ownsNotificationPopup && ((root.activeNotification !== null && (root.notificationCenter?.notificationPopupOpen ?? false)) || notificationPanel.progress > 0)
        implicitWidth: notificationPanel.length + notificationPanel.curveRadius
        implicitHeight: notificationPanel.depth + notificationPanel.curveRadius
        mask: Region {
            item: notificationPopupHost
        }

        WlrLayershell.namespace: "quickshell:topLeftNotification"
        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: true
            left: true
        }

        margins {
            top: Theme.barHeight + Theme.popupGap
            left: Theme.gap * 2
        }

        Item {
            id: notificationPopupHost

            anchors.fill: parent
            clip: false
            visible: notificationPopupWindow.visible

            Frame.PulloutPanel {
                id: notificationPanel

                corner: "topLeft"
                requestedOpen: root.ownsNotificationPopup && root.activeNotification !== null && (root.notificationCenter?.notificationPopupOpen ?? false)
                autoClose: false
                length: 390
                depth: Math.max(118, toastCard.implicitHeight + Theme.panelPadding * 2)
                duration: 180
                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    left: parent.left
                }

                NotificationCard {
                    id: toastCard

                    anchors.centerIn: parent
                    width: parent.width - Theme.panelPadding * 2
                    notification: root.activeNotification
                    toast: true
                    onDismissRequested: notification => root.notificationCenter?.dismissActiveNotification(notification)
                }
            }
        }
    }
}
