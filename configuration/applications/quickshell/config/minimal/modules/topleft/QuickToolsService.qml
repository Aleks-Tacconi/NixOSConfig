pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as ShellConfig

/**
 * Background helper service for calendar agenda syncing and desktop quick tools.
 */
Scope {
    id: root

    property string calendarPreview: "No events"
    property var calendarEvents: []
    property string agendaState: "idle"
    property string agendaError: ""
    property bool colorPickerActive: false
    property bool hyprsunsetTargetEnabled: false

    readonly property bool hyprsunsetEnabled: hyprsunsetProcess.running && hyprsunsetProcess.processId > 0
    readonly property bool hyprsunsetPending: root.hyprsunsetTargetEnabled !== root.hyprsunsetEnabled
    readonly property bool nightLightActive: root.hyprsunsetEnabled

    /** Query gcalcli for events surrounding the current month. */
    function refreshAgenda() {
        const now = new Date();
        const start = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() - 6, 1), "yyyy-MM-dd");
        const end = Qt.formatDateTime(new Date(now.getFullYear(), now.getMonth() + 13, 1), "yyyy-MM-dd");

        root.agendaState = "loading";
        root.agendaError = "";
        calendarProcess.exec(["gcalcli", "--nocolor", "agenda", "--nodeclined", "--military", "--tsv", "--details", "url", start, end]);
    }

    /** Alias for refreshing the calendar agenda. */
    function reloadAgenda() {
        root.refreshAgenda();
    }

    /** Parse a date and time string into a Date instance. */
    function parseEventDate(dateText, timeText, fallbackTime) {
        if (dateText.length === 0)
            return null;

        const parsed = new Date(`${dateText}T${timeText.length > 0 ? timeText : fallbackTime}`);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }

    /** Format a compact single-line preview for the next upcoming event. */
    function previewTextForEvent(event) {
        if (event.startAt === null)
            return event.title;

        const dateLabel = Qt.formatDateTime(event.startAt, "ddd d MMM");
        return event.startTime.length > 0 ? `${dateLabel} ${event.startTime} - ${event.title}` : `${dateLabel} - ${event.title}`;
    }

    /** Convert a single TSV line from gcalcli into an event record. */
    function parseAgendaLine(line) {
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
    }

    /** Update parsed agenda events and top-bar preview string. */
    function applyAgenda(output) {
        const events = output.trim().split("\n")
            .filter(line => line.length > 0 && !line.startsWith("start_date\t"))
            .map(line => root.parseAgendaLine(line));
        const now = new Date();
        const nextEvent = events.find(event => (event.endAt ?? event.startAt) !== null && (event.endAt ?? event.startAt) >= now) ?? null;

        root.calendarEvents = events;
        root.calendarPreview = nextEvent !== null ? root.previewTextForEvent(nextEvent) : "No events";
        root.agendaState = "ready";
    }

    /** Launch hyprpicker after closing any open top-left popup. */
    function pickColor() {
        root.colorPickerActive = true;
        colorPickerDelay.restart();
    }

    /** Capture a region screenshot to the Wayland clipboard. */
    function takeScreenshot() {
        screenshotProcess.exec(["hyprshot", "--silent", "-m", "region", "--clipboard"]);
    }

    /** Open a calendar event URL or its day view in the default browser. */
    function openCalendarEvent(event) {
        if (!event || calendarOpenProcess.running)
            return;

        const dayPath = event.date.replace(/-/g, "/");
        const url = event.url?.length > 0 ? event.url : `https://calendar.google.com/calendar/r/day/${dayPath}`;
        calendarOpenProcess.exec(["xdg-open", url]);
    }

    /** Toggle the managed hyprsunset night-light process when enabled. */
    function toggleHyprsunset() {
        if (!ShellConfig.Config.nightLight.enable || root.hyprsunsetPending)
            return;

        root.hyprsunsetTargetEnabled = !root.hyprsunsetEnabled;
        hyprsunsetProcess.running = root.hyprsunsetTargetEnabled;
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
}
