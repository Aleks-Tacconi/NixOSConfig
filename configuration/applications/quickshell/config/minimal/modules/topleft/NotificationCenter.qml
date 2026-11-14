pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../.." as ShellConfig

/**
 * Global background service managing notifications, agenda syncing, and desktop actions.
 */
Scope {
    id: root

    property bool dndEnabled: false
    property bool notificationPopupOpen: false
    property int notificationPulse: 0
    property int openMenuCount: 0
    property string notificationPopupScreenKey: ""
    property var notificationServer: notificationService
    property var notificationQueue: []
    property var toastEntries: []
    property bool toastHovered: false
    property var openMenuKeys: ({})
    property var centerOpenKeys: ({})

    signal menuActionRequested(string action)

    readonly property int notificationPopupTimeout: ShellConfig.Config.notifications.popupTimeout
    readonly property int notificationQueueLimit: ShellConfig.Config.notifications.queueLimit
    readonly property int notificationExitDuration: 180
    readonly property var notifications: root.notificationServer?.trackedNotifications ?? null
    readonly property var notificationValues: root.notifications?.values ?? []
    readonly property var newestNotifications: root.notificationValues.slice().reverse()
    readonly property var activeNotifications: root.toastEntries.map(entry => entry.notification)
    readonly property var activeNotification: root.activeNotifications[0] ?? null
    readonly property bool hasNotifications: root.notificationValues.length > 0
    readonly property int notificationCount: root.notificationValues.length
    readonly property bool menuOpen: openMenuCount > 0
    readonly property bool centerOpen: Object.keys(root.centerOpenKeys).length > 0
    readonly property alias calendarPreview: tools.calendarPreview
    readonly property alias calendarEvents: tools.calendarEvents
    readonly property alias agendaState: tools.agendaState
    readonly property alias agendaError: tools.agendaError
    readonly property alias colorPickerActive: tools.colorPickerActive
    readonly property alias hyprsunsetEnabled: tools.hyprsunsetEnabled
    readonly property alias hyprsunsetPending: tools.hyprsunsetPending
    readonly property alias nightLightActive: tools.nightLightActive

    function withScreenKey(keys, screenKey, present) {
        const next = Object.assign({}, keys);
        if (present) next[screenKey] = true;
        else delete next[screenKey];
        return next;
    }

    function setMenuOpen(screenKey, open) {
        root.openMenuKeys = root.withScreenKey(root.openMenuKeys, screenKey, open);
        root.openMenuCount = Object.keys(root.openMenuKeys).length;
    }

    function setCenterOpen(screenKey, open) { root.centerOpenKeys = root.withScreenKey(root.centerOpenKeys, screenKey, open); }
    function setNotificationPopupScreen(screenKey) { root.notificationPopupScreenKey = screenKey; }
    function clearNotificationPopupScreen(screenKey) {
        if (root.notificationPopupScreenKey === screenKey)
            root.notificationPopupScreenKey = "";
    }

    function isToastFading(notification) {
        return root.toastEntries.some(entry => entry.notification === notification && entry.fading);
    }

    function enqueueNotification(notification) {
        if (root.dndEnabled || root.centerOpen) return;
        if (root.menuOpen) {
            const next = root.notificationQueue.slice();
            next.push(notification);
            while (next.length > root.notificationQueueLimit) next.shift();
            root.notificationQueue = next;
            return;
        }
        root.pushToast(notification);
    }

    function pushToast(notification) {
        if (!notification) return;
        const now = Date.now();
        const next = root.toastEntries.filter(entry => entry.notification !== notification);
        next.push({
            notification: notification,
            remaining: root.notificationPopupTimeout,
            deadline: now + root.notificationPopupTimeout,
            fading: false,
            fadeDeadline: 0
        });
        while (next.length > root.notificationQueueLimit) next.shift();
        root.toastEntries = next;
        root.notificationPulse += 1;
        root.notificationPopupOpen = true;
    }

    function flushQueuedToasts() {
        if (root.dndEnabled || root.menuOpen || root.centerOpen || root.notificationQueue.length === 0) return;
        const queued = root.notificationQueue.slice();
        root.notificationQueue = [];
        for (const notification of queued) root.pushToast(notification);
    }

    function setActiveNotificationHovered(hovered) {
        if (root.toastHovered === hovered) return;
        root.toastHovered = hovered;
        const now = Date.now();
        root.toastEntries = root.toastEntries.map(entry => hovered
            ? Object.assign({}, entry, { remaining: Math.max(1, entry.deadline - now) })
            : Object.assign({}, entry, { deadline: now + entry.remaining }));
    }

    function removeToast(notification) {
        const next = root.toastEntries.filter(entry => entry.notification !== notification);
        root.toastEntries = next;
        if (next.length === 0) root.notificationPopupOpen = false;
    }

    function tickToasts() {
        const now = Date.now();
        let changed = false;
        const next = [];
        for (const entry of root.toastEntries) {
            if (!root.notificationValues.includes(entry.notification)) {
                changed = true;
                continue;
            }
            if (entry.fading) {
                if (now >= entry.fadeDeadline) { changed = true; continue; }
                next.push(entry);
                continue;
            }
            if (entry.notification.urgency !== NotificationUrgency.Critical && now >= entry.deadline) {
                changed = true;
                next.push(Object.assign({}, entry, { fading: true, fadeDeadline: now + root.notificationExitDuration }));
                continue;
            }
            next.push(entry);
        }
        if (!changed) return;
        root.toastEntries = next;
        if (next.length === 0) root.notificationPopupOpen = false;
    }

    function dismissActiveNotification(notification) {
        if (notification) root.removeToast(notification);
        else if (root.activeNotification) root.removeToast(root.activeNotification);
    }

    function dismissNotification(notification) {
        if (!notification) return;
        root.removeToast(notification);
        notification.dismiss();
    }

    function invokeNotificationAction(notification, action) {
        if (!notification || !action) return;
        root.removeToast(notification);
        const resident = notification.resident;
        action.invoke();
        if (resident) notification.dismiss();
    }

    function activateNotification(notification) {
        const actions = Array.from(notification?.actions ?? []);
        const defaultAction = actions.find(action => action.identifier === "default") ?? null;
        if (defaultAction === null) return false;
        root.invokeNotificationAction(notification, defaultAction);
        return true;
    }

    function suppressNotificationPopups() {
        root.notificationQueue = [];
        root.toastEntries = [];
        root.notificationPopupOpen = false;
    }

    function clearNotifications() {
        root.suppressNotificationPopups();
        for (const notification of root.notificationValues) notification.dismiss();
    }

    function refreshAgenda() { tools.refreshAgenda(); }
    function reloadAgenda() { tools.reloadAgenda(); }
    function openCalendarEvent(event) { tools.openCalendarEvent(event); }
    function pickColor() { tools.pickColor(); }
    function triggerColorPicker() { tools.pickColor(); }
    function takeScreenshot() { tools.takeScreenshot(); }
    function triggerRegionScreenshot() { tools.takeScreenshot(); }
    function toggleHyprsunset() { tools.toggleHyprsunset(); }
    function toggleNightLight() { tools.toggleHyprsunset(); }

    onDndEnabledChanged: root.dndEnabled ? root.suppressNotificationPopups() : root.flushQueuedToasts()
    onCenterOpenChanged: { if (root.centerOpen) root.suppressNotificationPopups(); }
    onMenuOpenChanged: {
        if (root.menuOpen) {
            root.setActiveNotificationHovered(true);
            root.notificationPopupOpen = false;
        } else {
            root.setActiveNotificationHovered(false);
            if (root.toastEntries.length > 0 && !root.dndEnabled && !root.centerOpen) root.notificationPopupOpen = true;
            root.flushQueuedToasts();
        }
    }

    QuickToolsService { id: tools }

    IpcHandler {
        target: "notifications"
        function toggle() { root.menuActionRequested("toggle"); }
        function open() { root.menuActionRequested("open"); }
        function close() { root.menuActionRequested("close"); }
    }

    NotificationServer {
        id: notificationService
        bodySupported: true; bodyMarkupSupported: false; actionsSupported: true
        imageSupported: true; persistenceSupported: true; keepOnReload: true
        onNotification: notification => {
            notification.tracked = true;
            if (!notification.lastGeneration) root.enqueueNotification(notification);
        }
    }

    Timer {
        id: toastTickTimer
        interval: 80
        repeat: true
        running: root.toastEntries.length > 0 && !root.toastHovered && !root.dndEnabled && !root.menuOpen
        onTriggered: root.tickToasts()
    }
}
