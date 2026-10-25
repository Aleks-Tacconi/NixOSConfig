pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../frame" as Frame
import "../../theme"

/**
 * Top-left status cluster with time, notifications, and calendar preview.
 */
Item {
    id: root

    width: statusFrame.width
    height: Theme.barHeight

    property var popupScreen: null
    property real maxWidth: 430
    property var notificationCenter: null
    property string openPopup: ""
    readonly property bool calendarOpen: root.openPopup === "calendar"
    readonly property bool notificationsOpen: root.openPopup === "notifications"
    readonly property string currentScreenKey: screenKey(root.popupScreen)
    readonly property bool colorPickerActive: root.notificationCenter?.colorPickerActive ?? false
    readonly property bool menuOpen: !root.colorPickerActive && (root.notificationsOpen || root.calendarOpen || notificationsPanel.progress > 0 || calendarPanel.progress > 0)
    readonly property bool ownsNotificationPopup: root.notificationCenter !== null && root.notificationCenter.notificationPopupScreenKey === root.currentScreenKey
    readonly property var activeNotification: root.notificationCenter?.activeNotification ?? null
    readonly property real notificationPanelDepth: Math.max(0, (root.popupScreen?.height ?? 1080) - Theme.barHeight - Theme.popupGap * 2)
    readonly property real calendarPanelDepth: Math.max(0, (root.popupScreen?.height ?? 1080) - Theme.barHeight - Theme.popupGap * 2)

    function notificationIcon() {
        return root.notificationCenter?.dndEnabled ? "󰂛" : "󰂚";
    }

    function screenKey(screen) {
        if (screen === null || screen === undefined)
            return "";

        return screen.name ?? `${screen.x},${screen.y}:${screen.width}x${screen.height}`;
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
        root.notificationCenter?.setCenterOpen(root.currentScreenKey, false);
        root.notificationCenter?.clearNotificationPopupScreen(root.currentScreenKey);
    }

    onMenuOpenChanged: {
        root.notificationCenter?.setMenuOpen(root.currentScreenKey, root.menuOpen);
    }

    onNotificationsOpenChanged: {
        root.notificationCenter?.setCenterOpen(root.currentScreenKey, root.notificationsOpen);
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

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: statusContent.implicitWidth

        Row {
            id: statusContent

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            spacing: Theme.gap * 6

            Item {
                id: calendarSegment

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                z: calendarTrigger.containsMouse ? 1 : 0
                width: calendarStatusRow.implicitWidth

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
                    height: 28
                    color: calendarTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                Row {
                    id: calendarStatusRow

                    anchors.centerIn: parent
                    spacing: Theme.gap * 6

                    StatusCell {
                        id: clockStatus
                        labelFontFamily: Theme.monoFontFamily
                        icon: ""
                        label: Qt.formatDateTime(clockTimer.now, "hh:mm")
                    }

                    StatusCell {
                        icon: "󰃭"
                        label: root.notificationCenter?.calendarPreview ?? "No events"
                        labelColor: Theme.muted
                        labelMaxWidth: Math.max(0, Math.min(220, root.maxWidth - clockStatus.width - notificationsSegment.width - statusContent.spacing - calendarStatusRow.spacing - Theme.fontSize - Theme.gap * 2))
                        visible: labelMaxWidth >= Theme.fontSize * 4
                        scrollLabel: true
                        scrollActive: calendarTrigger.containsMouse
                    }
                }

                MouseArea {
                    id: calendarTrigger

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        bottomMargin: -Theme.popupGap
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.togglePopup("calendar")
                }
            }

            Item {
                id: notificationsSegment

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                z: notificationsTrigger.containsMouse ? 1 : 0
                width: notificationsStatus.width

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
                    height: 28
                    color: notificationsTrigger.containsMouse ? Theme.panelSurfaceHover : "transparent"
                    radius: Theme.radius
                }

                StatusCell {
                    id: notificationsStatus

                    anchors.centerIn: parent
                    icon: root.notificationIcon()
                    label: root.notificationCenter?.hasNotifications ? String(root.notificationCenter.notificationCount) : ""
                    dotVisible: root.notificationCenter?.hasNotifications ?? false
                }

                MouseArea {
                    id: notificationsTrigger

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        bottomMargin: -Theme.popupGap
                        left: parent.left
                        right: parent.right
                        leftMargin: -Theme.gap * 2
                        rightMargin: -Theme.gap * 2
                    }
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
        WlrLayershell.keyboardFocus: root.notificationsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                clickDismiss: true
                onDismissRequested: root.closePopup("notifications")

                length: 430
                depth: root.notificationPanelDepth
                duration: 150

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

                    spacing: Theme.panelSectionGap

                    Item {
                        id: notificationSection

                        width: parent.width
                        height: Math.max(0, parent.height - quickActionsSection.height - (quickActionsSection.visible ? parent.spacing : 0))
                        clip: true

                        Column {
                            id: notificationSectionContent

                            anchors {
                                fill: parent
                                margins: Theme.gap
                            }
                            spacing: Theme.panelItemGap

                            Item {
                                width: parent.width
                                height: 30

                                Frame.PanelSectionHeader {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        rightMargin: clearButton.visible ? clearButton.width + Theme.gap * 2 : 0
                                        verticalCenter: parent.verticalCenter
                                    }
                                    title: "Notifications"
                                    detail: ""
                                }

                                Rectangle {
                                    id: clearButton

                                    anchors {
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                    }
                                    visible: root.notificationCenter?.hasNotifications ?? false
                                    width: 68
                                    height: 28
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

                                    anchors {
                                        fill: parent
                                        rightMargin: Theme.gap * 2
                                    }
                                    spacing: Theme.gap
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ScriptModel {
                                        values: root.notificationCenter?.newestNotifications ?? []
                                    }

                                    displaced: Transition {
                                        NumberAnimation {
                                            property: "y"
                                            duration: 150
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    delegate: NotificationCard {
                                        required property var modelData

                                        width: ListView.view.width
                                        notification: modelData
                                        onDismissRequested: notification => root.notificationCenter?.dismissNotification(notification)
                                        onActionRequested: (notification, action) => root.notificationCenter?.invokeNotificationAction(notification, action)
                                        onActivated: notification => {
                                            if (root.notificationCenter?.activateNotification(notification))
                                                root.closePopup("notifications");
                                        }
                                    }
                                }

                                Frame.PanelScrollIndicator {
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        bottom: parent.bottom
                                        rightMargin: 1
                                    }
                                    flickable: notificationsList
                                }
                            }
                        }
                    }

                    Item {
                        id: quickActionsSection

                        visible: root.notificationPanelDepth >= 400
                        width: parent.width
                        height: visible ? quickActionsContent.implicitHeight + Theme.gap * 2 : 0

                        Column {
                            id: quickActionsContent

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Theme.gap
                            }
                            spacing: Theme.panelItemGap

                            Frame.PanelGroupLabel {
                                width: parent.width
                                title: "Quick actions"
                            }

                            Column {
                                id: actionBar

                                width: parent.width
                                height: implicitHeight
                                spacing: Theme.gap

                                ActionButton {
                                    width: actionBar.width
                                    label: "Do Not Disturb"
                                    icon: "󰂛"
                                    active: root.notificationCenter?.dndEnabled ?? false
                                    detailText: active ? "On" : "Off"
                                    onClicked: {
                                        if (root.notificationCenter !== null)
                                            root.notificationCenter.dndEnabled = !root.notificationCenter.dndEnabled;
                                    }
                                }

                                ActionButton {
                                    width: actionBar.width
                                    label: "Pick Color"
                                    icon: ""
                                    onClicked: root.notificationCenter?.pickColor()
                                }

                                ActionButton {
                                    width: actionBar.width
                                    label: "Night Light"
                                    icon: "󰖔"
                                    active: root.notificationCenter?.hyprsunsetEnabled ?? false
                                    enabled: !(root.notificationCenter?.hyprsunsetPending ?? false)
                                    detailText: (root.notificationCenter?.hyprsunsetEnabled ?? false) ? "On" : "Off"
                                    onClicked: root.notificationCenter?.toggleHyprsunset()
                                }

                                ActionButton {
                                    width: actionBar.width
                                    label: "Screenshot"
                                    icon: ""
                                    onClicked: root.notificationCenter?.takeScreenshot()
                                }
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
        WlrLayershell.keyboardFocus: root.calendarOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                clickDismiss: true
                onDismissRequested: root.closePopup("calendar")

                length: 430
                depth: root.calendarPanelDepth
                duration: 180

                backgroundColor: Theme.panelBg
                curveRadius: Theme.panelRadius

                anchors {
                    top: parent.top
                    left: parent.left
                }

                CalendarMonth {
                    anchors {
                        fill: parent
                        margins: Theme.panelPadding
                    }
                    events: root.notificationCenter?.calendarEvents ?? []
                    onEventOpenRequested: event => {
                        root.closePopup("calendar");
                        root.notificationCenter?.openCalendarEvent(event);
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
                    onDismissRequested: notification => root.notificationCenter?.dismissNotification(notification)
                    onActionRequested: (notification, action) => root.notificationCenter?.invokeNotificationAction(notification, action)
                    onActivated: notification => {
                        if (!root.notificationCenter?.activateNotification(notification))
                            root.openPopup = "notifications";
                    }
                    onInteractionChanged: interacting => root.notificationCenter?.setActiveNotificationHovered(interacting)
                }
            }
        }
    }
}
