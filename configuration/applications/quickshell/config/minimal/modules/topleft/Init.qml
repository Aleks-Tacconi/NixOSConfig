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

    width: statusContent.implicitWidth
    height: Theme.barHeight

    property var popupScreen: null
    property real barLeftMargin: Theme.gap * 4
    property real maxWidth: 430
    property var notificationCenter: null
    property string openPopup: ""
    property bool wallpaperPickerOpen: false

    readonly property bool calendarOpen: root.openPopup === "calendar"
    readonly property bool notificationsOpen: root.openPopup === "notifications"
    readonly property string currentScreenKey: root.screenKey(root.popupScreen)
    readonly property bool colorPickerActive: root.notificationCenter?.colorPickerActive ?? false
    readonly property bool menuOpen: !root.colorPickerActive
        && (root.notificationsOpen || root.calendarOpen || notificationsWindow.progress > 0 || calendarWindow.progress > 0)
    readonly property bool ownsNotificationPopup: root.notificationCenter !== null
        && root.notificationCenter.notificationPopupScreenKey === root.currentScreenKey
    readonly property var activeNotifications: root.notificationCenter?.activeNotifications ?? []
    readonly property bool toastShouldShow: root.ownsNotificationPopup
        && root.activeNotifications.length > 0 && (root.notificationCenter?.notificationPopupOpen ?? false)
    readonly property real panelDepth: Math.max(0, (root.popupScreen?.height ?? 1080) - Theme.barHeight - Theme.popupGap * 2)
    readonly property real notificationsWidth: 390
    readonly property real notificationsPopupLeftMargin: Theme.gap * 2
    property var toastHeights: ({})

    function setToastHeight(index, height) {
        if (root.toastHeights[index] === height)
            return;
        const next = Object.assign({}, root.toastHeights);
        next[index] = height;
        root.toastHeights = next;
    }

    function toastOffsetFor(index) {
        let offset = 0;
        for (let i = 0; i < index; i += 1)
            offset += (root.toastHeights[i] ?? 0) + Theme.gap * 2;
        return offset;
    }

    function notificationIcon() { return root.notificationCenter?.dndEnabled ? "󰂛" : "󰂚"; }
    function isFocusedScreen() { return Hyprland.monitorFor(root.popupScreen)?.focused ?? false; }
    function togglePopup(name) { root.openPopup = root.openPopup === name ? "" : name; }
    function closePopup(name) { if (root.openPopup === name) root.openPopup = ""; }
    function screenKey(screen) {
        return screen ? (screen.name ?? `${screen.x},${screen.y}:${screen.width}x${screen.height}`) : "";
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

    onMenuOpenChanged: root.notificationCenter?.setMenuOpen(root.currentScreenKey, root.menuOpen)
    onColorPickerActiveChanged: { if (root.colorPickerActive) root.openPopup = ""; }
    onNotificationsOpenChanged: {
        if (!root.notificationsOpen) root.wallpaperPickerOpen = false;
        root.notificationCenter?.setCenterOpen(root.currentScreenKey, root.notificationsOpen);
    }

    Connections {
        target: root.notificationCenter
        function onNotificationPulseChanged() {
            if (root.isFocusedScreen()) root.notificationCenter?.setNotificationPopupScreen(root.currentScreenKey);
        }
        function onMenuActionRequested(action) {
            if (action === "close" || !root.isFocusedScreen()) root.closePopup("notifications");
            else if (action === "toggle") root.togglePopup("notifications");
            else if (action === "open") root.openPopup = "notifications";
        }
    }

    Row {
        id: statusContent
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        spacing: Theme.gap * 6

        Frame.BarPillButton {
            id: clockButton
            width: calendarStatusRow.implicitWidth; active: root.calendarOpen; pillHeight: 28
            pillLeftMargin: -Theme.gap * 2; pillRightMargin: -Theme.gap * 2
            onClicked: root.togglePopup("calendar")

            Row {
                id: calendarStatusRow
                anchors.centerIn: parent; spacing: Theme.gap * 6

                StatusCell {
                    id: clockStatus
                    labelFontFamily: Theme.monoFontFamily; icon: ""
                    label: Qt.formatDateTime(clockTimer.now, "hh:mm")
                }

                StatusCell {
                    icon: "󰃭"; label: root.notificationCenter?.calendarPreview ?? "No events"
                    labelColor: Theme.muted
                    labelMaxWidth: Math.max(0, Math.min(220, root.maxWidth - clockStatus.width - notificationsButton.width - statusContent.spacing - calendarStatusRow.spacing - Theme.fontSize - Theme.gap * 2))
                    visible: labelMaxWidth >= Theme.fontSize * 4
                    scrollLabel: true; scrollActive: clockButton.hovered
                }
            }
        }

        Frame.BarPillButton {
            id: notificationsButton
            width: notificationsStatus.width; active: root.notificationsOpen; pillHeight: 28
            pillLeftMargin: -Theme.gap * 2; pillRightMargin: -Theme.gap * 2
            onClicked: root.togglePopup("notifications")

            StatusCell {
                id: notificationsStatus
                anchors.centerIn: parent; icon: root.notificationIcon()
                label: root.notificationCenter?.hasNotifications ? String(root.notificationCenter.notificationCount) : ""
                dotVisible: root.notificationCenter?.hasNotifications ?? false
            }
        }
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: now = new Date()
    }

    Frame.BarPopupWindow {
        id: notificationsWindow
        popupScreen: root.popupScreen; alignEdge: "left"
        namespace: "quickshell:topLeftNotificationsPullout"
        requestedOpen: root.notificationsOpen && !root.colorPickerActive
        forceClose: root.colorPickerActive
        activatorMouseArea: notificationsButton.mouseArea; hoverBridgeActivator: notificationsButton.mouseArea
        hoverBridgeX: root.barLeftMargin + statusContent.x + notificationsButton.x + notificationsButton.mouseArea.x - Theme.gap * 2
        panelWidth: 430; panelDepth: root.panelDepth; duration: 150
        onDismissRequested: root.closePopup("notifications")

        NotificationsPanel {
            id: notificationsPanelView
            anchors.fill: parent; notificationCenter: root.notificationCenter
            wallpaperPickerOpen: root.wallpaperPickerOpen; panelDepth: root.panelDepth
            onWallpaperPickerOpenChanged: root.wallpaperPickerOpen = notificationsPanelView.wallpaperPickerOpen
            onCloseRequested: root.closePopup("notifications")
        }
    }

    Frame.BarPopupWindow {
        id: calendarWindow
        popupScreen: root.popupScreen; alignEdge: "left"
        namespace: "quickshell:topLeftCalendarPullout"
        requestedOpen: root.calendarOpen && !root.colorPickerActive
        forceClose: root.colorPickerActive
        activatorMouseArea: clockButton.mouseArea; hoverBridgeActivator: clockButton.mouseArea
        hoverBridgeX: root.barLeftMargin + statusContent.x + clockButton.x + clockButton.mouseArea.x - Theme.gap * 2
        panelWidth: 430; panelDepth: root.panelDepth; duration: 180
        onDismissRequested: root.closePopup("calendar")

        CalendarMonth {
            anchors.fill: parent
            events: root.notificationCenter?.calendarEvents ?? []
            agendaError: root.notificationCenter?.agendaError ?? ""
            onEventOpenRequested: event => {
                root.closePopup("calendar");
                root.notificationCenter?.openCalendarEvent(event);
            }
        }
    }

    Variants {
        model: ScriptModel { values: root.activeNotifications }

        PanelWindow {
            id: toastWindow

            required property var modelData
            required property int index

            screen: root.popupScreen
            visible: root.toastShouldShow && !root.calendarOpen && !root.notificationsOpen
            anchors { top: true; left: true }
            // qmllint disable unqualified unresolved-type
            margins {
                top: Theme.barHeight + Theme.popupGap + root.toastOffsetFor(toastWindow.index)
                left: root.notificationsPopupLeftMargin
                Behavior on top { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
            // qmllint enable unqualified unresolved-type
            WlrLayershell.namespace: "quickshell:topLeftNotification"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: root.notificationsWidth
            implicitHeight: Math.max(1, toastSurface.implicitHeight)
            onImplicitHeightChanged: root.setToastHeight(toastWindow.index, toastWindow.implicitHeight)
            Component.onCompleted: root.setToastHeight(toastWindow.index, toastWindow.implicitHeight)

            Frame.PanelSurface {
                id: toastSurface

                anchors.fill: parent
                implicitHeight: toastCard.implicitHeight + Theme.gap * 2
                opacity: (root.notificationCenter?.isToastFading(toastWindow.modelData) ?? false) ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }

                NotificationCard {
                    id: toastCard

                    anchors { fill: parent; margins: Theme.gap }
                    notification: toastWindow.modelData
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
