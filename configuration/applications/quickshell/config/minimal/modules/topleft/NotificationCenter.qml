import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../.." as ShellConfig

Scope {
    id: root

    property bool dndEnabled: false
    property bool notificationPopupOpen: false
    property int notificationPulse: 0
    property int openMenuCount: 0
    property string notificationPopupScreenKey: ""
    property string calendarPreview: "No events"
    property var calendarEvents: []
    property bool colorPickerActive: false
    property var notificationServer: notificationService
    property var notificationQueue: []
    property var activeNotification: null
    property int activeNotificationRemaining: notificationPopupTimeout
    property double activeNotificationDeadline: 0
    property bool discardActiveAfterExit: false
    property bool hyprsunsetTargetEnabled: false

    signal menuActionRequested(string action)

    readonly property int notificationPopupTimeout: ShellConfig.Config.notifications.popupTimeout
    readonly property int notificationQueueLimit: ShellConfig.Config.notifications.queueLimit
    readonly property int notificationExitDuration: 180
    readonly property var notifications: root.notificationServer?.trackedNotifications ?? null
    readonly property var notificationValues: root.notifications?.values ?? []
    readonly property var newestNotifications: root.notificationValues.slice().reverse()
    readonly property bool hasNotifications: root.notificationValues.length > 0
    readonly property int notificationCount: root.notificationValues.length
    readonly property bool menuOpen: openMenuCount > 0
    readonly property bool hyprsunsetEnabled: hyprsunsetProcess.running && hyprsunsetProcess.processId > 0
    readonly property bool hyprsunsetPending: root.hyprsunsetTargetEnabled !== root.hyprsunsetEnabled

    property var openMenuKeys: ({})

    function setMenuOpen(screenKey, open) {
        const next = root.openMenuKeys;

        if (open)
            next[screenKey] = true;
        else
            delete next[screenKey];

        root.openMenuKeys = next;
        root.openMenuCount = Object.keys(next).length;
    }

    function setNotificationPopupScreen(screenKey) {
        root.notificationPopupScreenKey = screenKey;
    }

    function clearNotificationPopupScreen(screenKey) {
        if (root.notificationPopupScreenKey === screenKey)
            root.notificationPopupScreenKey = "";
    }

    function enqueueNotification(notification) {
        if (root.dndEnabled)
            return;

        const next = root.notificationQueue.slice();
        next.push(notification);

        while (next.length > root.notificationQueueLimit)
            next.shift();

        root.notificationQueue = next;
        root.showNextNotification();
    }

    function showNextNotification() {
        if (root.dndEnabled || root.menuOpen || root.activeNotification !== null || notificationExitTimer.running)
            return;

        const next = root.notificationQueue.slice();
        let notification = null;

        while (next.length > 0 && notification === null)
            notification = next.shift() ?? null;

        root.notificationQueue = next;

        if (notification === null)
            return;

        root.activeNotification = notification;
        root.activeNotificationRemaining = root.notificationPopupTimeout;
        root.notificationPulse += 1;
        root.resumeActiveNotification();
    }

    function resumeActiveNotification() {
        if (root.activeNotification === null || root.dndEnabled || root.menuOpen)
            return;

        const remaining = Math.max(1, root.activeNotificationRemaining);
        root.activeNotificationDeadline = Date.now() + remaining;
        root.notificationPopupOpen = true;
        notificationDwellTimer.interval = remaining;
        notificationDwellTimer.restart();
    }

    function pauseActiveNotification() {
        if (root.activeNotification === null || !root.notificationPopupOpen || !notificationDwellTimer.running)
            return;

        root.activeNotificationRemaining = Math.max(1, root.activeNotificationDeadline - Date.now());
        notificationDwellTimer.stop();
    }

    function setActiveNotificationHovered(hovered) {
        if (hovered)
            root.pauseActiveNotification();
        else if (root.notificationPopupOpen && !notificationDwellTimer.running)
            root.resumeActiveNotification();
    }

    function hideActiveNotification(discard) {
        const wasVisible = root.notificationPopupOpen;
        notificationDwellTimer.stop();

        if (!discard && wasVisible)
            root.activeNotificationRemaining = Math.max(0, root.activeNotificationDeadline - Date.now());

        root.notificationPopupOpen = false;

        if (notificationExitTimer.running) {
            root.discardActiveAfterExit = root.discardActiveAfterExit || discard;
            return;
        }

        root.discardActiveAfterExit = discard;

        if (wasVisible) {
            notificationExitTimer.restart();
            return;
        }

        root.finishNotificationExit();
    }

    function finishNotificationExit() {
        if (root.discardActiveAfterExit) {
            root.activeNotification = null;
            root.activeNotificationDeadline = 0;
            root.activeNotificationRemaining = root.notificationPopupTimeout;
        }

        root.discardActiveAfterExit = false;

        if (root.dndEnabled || root.menuOpen)
            return;

        if (root.activeNotification !== null)
            root.resumeActiveNotification();
        else
            root.showNextNotification();
    }

    function dismissActiveNotification(notification) {
        if (root.activeNotification !== null && (notification === undefined || notification === root.activeNotification))
            root.hideActiveNotification(true);
    }

    function dismissNotification(notification) {
        if (!notification)
            return;
        if (notification === root.activeNotification)
            root.hideActiveNotification(true);
        notification.dismiss();
    }

    function invokeNotificationAction(notification, action) {
        if (!notification || !action)
            return;
        if (notification === root.activeNotification)
            root.hideActiveNotification(true);
        action.invoke();
    }

    function suppressNotificationPopups() {
        root.notificationQueue = [];

        if (root.activeNotification !== null)
            root.hideActiveNotification(true);
    }

    function clearNotifications() {
        root.suppressNotificationPopups();

        for (const notification of root.notificationValues)
            notification.dismiss();
    }

    function refreshAgenda() {
        const now = new Date();
        const start = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() - 6, 1), "yyyy-MM-dd");
        const end = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() + 13, 1), "yyyy-MM-dd");

        calendarProcess.exec(["gcalcli", "--nocolor", "agenda", "--nodeclined", "--military", "--tsv", "--details", "url", start, end]);
    }

    function parseEventDate(dateText, timeText, fallbackTime) {
        if (dateText.length === 0)
            return null;

        const parsed = new Date(`${dateText}T${timeText.length > 0 ? timeText : fallbackTime}`);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }

    function previewTextForEvent(event) {
        if (event.startAt === null)
            return event.title;

        const dateLabel = Qt.formatDateTime(event.startAt, "ddd d MMM");
        return event.startTime.length > 0 ? `${dateLabel} ${event.startTime} - ${event.title}` : `${dateLabel} - ${event.title}`;
    }

    function applyAgenda(output) {
        const events = output.trim().split("\n").filter(line => line.length > 0 && !line.startsWith("start_date\t")).map(line => {
            const parts = line.split("\t");
            const title = (parts[6] ?? parts[4] ?? parts.slice(2).join(" ")).trim();
            const startDate = parts[0] ?? "";
            const startTime = parts[1] ?? "";
            const endDate = parts[2] ?? "";
            const endTime = parts[3] ?? "";
            const startAt = root.parseEventDate(startDate, startTime, "00:00");
            const endAt = root.parseEventDate(endDate.length > 0 ? endDate : startDate, endTime, startTime.length > 0 ? startTime : "23:59") ?? startAt;

            return {
                date: startDate,
                startTime: startTime,
                endDate: endDate,
                endTime: endTime,
                time: parts.length >= 5 ? `${startDate} ${startTime}`.trim() : parts.slice(0, 2).join(" ").trim(),
                startAt: startAt,
                endAt: endAt,
                url: parts.length >= 7 ? parts[4] : "",
                title: title.length > 0 ? title : line.trim()
            };
        });
        const now = new Date();
        const nextEvent = events.find(event => (event.endAt ?? event.startAt) !== null && (event.endAt ?? event.startAt) >= now) ?? null;
        const previewTitle = nextEvent !== null ? root.previewTextForEvent(nextEvent) : "No events";

        root.calendarEvents = events;
        root.calendarPreview = previewTitle;
    }

    function pickColor() {
        root.colorPickerActive = true;
        colorPickerDelay.restart();
    }

    function takeScreenshot() {
        screenshotProcess.exec(["hyprshot", "--silent", "-m", "region", "--clipboard"]);
    }

    function openCalendarEvent(event) {
        if (!event || calendarOpenProcess.running)
            return;
        const dayPath = event.date.replace(/-/g, "/");
        const url = event.url?.length > 0 ? event.url : `https://calendar.google.com/calendar/r/day/${dayPath}`;
        calendarOpenProcess.exec(["xdg-open", url]);
    }

    function toggleHyprsunset() {
        if (root.hyprsunsetPending)
            return;

        root.hyprsunsetTargetEnabled = !root.hyprsunsetEnabled;
        hyprsunsetProcess.running = root.hyprsunsetTargetEnabled;
    }

    onDndEnabledChanged: {
        if (root.dndEnabled)
            root.suppressNotificationPopups();
        else
            root.showNextNotification();
    }

    onMenuOpenChanged: {
        if (root.menuOpen) {
            if (root.activeNotification !== null && root.notificationPopupOpen)
                root.hideActiveNotification(false);

            return;
        }

        if (!notificationExitTimer.running)
            root.finishNotificationExit();
    }

    IpcHandler {
        target: "notifications"

        function toggle() {
            root.menuActionRequested("toggle");
        }

        function open() {
            root.menuActionRequested("open");
        }

        function close() {
            root.menuActionRequested("close");
        }
    }

    NotificationServer {
        id: notificationService

        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            if (!notification.lastGeneration)
                root.enqueueNotification(notification);
        }
    }

    Timer {
        id: notificationDwellTimer

        onTriggered: root.hideActiveNotification(true)
    }

    Timer {
        id: notificationExitTimer

        interval: root.notificationExitDuration
        onTriggered: root.finishNotificationExit()
    }

    Timer {
        id: colorPickerDelay

        interval: 260
        onTriggered: colorPickerProcess.exec(["hyprpicker", "-a", "-f", "hex"])
    }

    Timer {
        interval: 300000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshAgenda()
    }

    Process {
        id: calendarProcess

        stdout: StdioCollector {
            id: calendarOutput

            onStreamFinished: root.applyAgenda(calendarOutput.text)
        }
    }

    Process {
        id: colorPickerProcess

        onExited: root.colorPickerActive = false
    }

    Process {
        id: hyprsunsetProcess

        command: ["hyprsunset", "-t", String(ShellConfig.Config.nightLight.temperature)]
        onExited: root.hyprsunsetTargetEnabled = false
    }

    Process {
        id: screenshotProcess
    }

    Process {
        id: calendarOpenProcess
    }

    Connections {
        target: root.activeNotification
        enabled: root.activeNotification !== null
        ignoreUnknownSignals: true

        function onClosed() {
            root.dismissActiveNotification();
        }
    }
}
