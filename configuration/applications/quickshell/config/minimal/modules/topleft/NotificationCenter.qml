import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

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
    property bool hyprsunsetEnabled: false
    property var notificationServer: notificationService

    signal menuActionRequested(string action)

    readonly property var notifications: root.notificationServer?.trackedNotifications ?? null
    readonly property var notificationValues: root.notifications?.values ?? []
    readonly property bool hasNotifications: root.notificationValues.length > 0
    readonly property int notificationCount: root.notificationValues.length
    readonly property bool menuOpen: openMenuCount > 0

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

    function showNotificationPopup() {
        root.notificationPulse += 1;

        if (root.dndEnabled || root.menuOpen)
            return;

        root.notificationPopupOpen = true;
        notificationPopupTimer.restart();
    }

    function clearNotifications() {
        for (const notification of root.notificationValues)
            notification.dismiss();
    }

    function latestNotification() {
        const values = root.notificationValues;

        return values.length > 0 ? values[values.length - 1] : null;
    }

    function refreshAgenda() {
        const now = new Date();
        const start = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() - 6, 1), "yyyy-MM-dd");
        const end = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() + 13, 1), "yyyy-MM-dd");

        calendarProcess.exec(["gcalcli", "--nocolor", "agenda", "--nodeclined", "--military", "--tsv", start, end]);
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
            const title = (parts[4] ?? parts.slice(2).join(" ")).trim();
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

    function refreshHyprsunset() {
        hyprsunsetStatusProcess.exec(["pgrep", "-x", "hyprsunset"]);
    }

    function takeScreenshot() {
        screenshotProcess.exec(["hyprshot", "-m", "region", "--clipboard"]);
    }

    function toggleHyprsunset() {
        if (root.hyprsunsetEnabled) {
            hyprsunsetStopProcess.exec(["pkill", "-x", "hyprsunset"]);
            root.hyprsunsetEnabled = false;
            return;
        }

        hyprsunsetStartProcess.exec(["hyprsunset", "-t", "3500"]);
        root.hyprsunsetEnabled = true;
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
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            if (!notification.lastGeneration)
                root.showNotificationPopup();
        }
    }

    Timer {
        id: notificationPopupTimer

        interval: 4800
        onTriggered: root.notificationPopupOpen = false
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

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshHyprsunset()
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
        id: hyprsunsetStatusProcess

        stdout: StdioCollector {
            id: hyprsunsetStatusOutput

            onStreamFinished: root.hyprsunsetEnabled = hyprsunsetStatusOutput.text.trim().length > 0
        }
    }

    Process {
        id: hyprsunsetStartProcess
    }

    Process {
        id: hyprsunsetStopProcess

        onExited: root.refreshHyprsunset()
    }

    Process {
        id: screenshotProcess
    }
}
