pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "calendar-data.js" as CalendarData
import "../../theme"
import "../frame" as Frame

/** Month selection and a quiet, scrollable agenda of populated dates. */
Item {
    id: root

    property var events: []
    property date visibleMonth: new Date()
    property string selectedKey: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    property date clockNow: new Date()
    readonly property string todayKey: Qt.formatDateTime(root.clockNow, "yyyy-MM-dd")
    readonly property var scheduleDays: CalendarData.buildScheduleDays(root.events, root.visibleMonth, root.clockNow)
    readonly property var agendaDays: CalendarData.visibleDays(root.scheduleDays, root.selectedKey)

    signal eventOpenRequested(var event)

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.clockNow = new Date()
    }

    onVisibleChanged: {
        if (root.visible)
            root.returnToToday();
    }
    onEventsChanged: Qt.callLater(() => root.scrollToDate(root.selectedKey, false))
    Component.onCompleted: Qt.callLater(() => root.scrollToDate(root.selectedKey, false))

    /** Show another month's agenda without inventing a selected day. */
    function changeMonth(delta) {
        root.visibleMonth = new Date(root.visibleMonth.getFullYear(), root.visibleMonth.getMonth() + delta, 1);
        root.selectedKey = "";
        agendaScroll.stop();
        Qt.callLater(() => agendaList.positionViewAtBeginning());
    }

    /** Return both month and agenda to the current day. */
    function returnToToday() {
        root.clockNow = new Date();
        root.selectDate(root.todayKey);
    }

    /** Keep explicit date selection stable while the user scrolls the agenda. */
    function selectDate(key) {
        const parts = key.split("-").map(Number);
        if (root.visibleMonth.getFullYear() !== parts[0] || root.visibleMonth.getMonth() !== parts[1] - 1)
            root.visibleMonth = new Date(parts[0], parts[1] - 1, 1);
        root.selectedKey = key;
        Qt.callLater(() => root.scrollToDate(key, true));
    }

    /** Reveal a selected day, animating only when its delegate is available. */
    function scrollToDate(key, animate) {
        const index = root.agendaDays.findIndex(day => day.dateKey === key);
        if (index < 0)
            return;
        agendaScroll.stop();
        agendaList.forceLayout();
        const item = agendaList.itemAtIndex(index);
        if (animate && item) {
            agendaScroll.to = Math.max(agendaList.originY, Math.min(item.y,
                agendaList.originY + Math.max(0, agendaList.contentHeight - agendaList.height)));
            agendaScroll.restart();
        } else {
            agendaList.positionViewAtIndex(index, ListView.Beginning);
        }
    }

    Row {
        id: dateHeader
        width: parent.width
        spacing: Theme.panelItemGap

        Text {
            text: Qt.formatDateTime(root.clockNow, "dd")
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.displaySize
            font.bold: true
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: Qt.formatDateTime(root.clockNow, "dddd")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelTitleSize
                font.bold: true
            }
            Text {
                text: Qt.formatDateTime(root.clockNow, "MMMM yyyy")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
            }
        }
    }

    CalendarMonthGrid {
        id: monthGrid
        anchors {
            top: dateHeader.bottom
            topMargin: Theme.panelSectionGap
            left: parent.left
            right: parent.right
        }
        month: root.visibleMonth
        selectedKey: root.selectedKey
        todayKey: root.todayKey
        events: root.events
        onDateSelected: key => root.selectDate(key)
        onMonthRequested: delta => root.changeMonth(delta)
        onTodayRequested: root.returnToToday()
    }

    Frame.PanelDivider {
        id: divider
        anchors {
            top: monthGrid.bottom
            topMargin: Theme.panelSectionGap
            left: parent.left
            right: parent.right
        }
        fullWidth: true
    }

    ListView {
        id: agendaList
        anchors {
            top: divider.bottom
            topMargin: Theme.panelSectionGap
            left: parent.left
            right: parent.right
            rightMargin: Theme.panelItemGap
            bottom: parent.bottom
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: Theme.panelSectionGap
        model: ScriptModel { values: root.agendaDays }
        onMovementStarted: agendaScroll.stop()

        delegate: CalendarAgendaDay {
            required property var modelData
            width: ListView.view.width
            day: modelData
            now: root.clockNow
            onEventOpenRequested: event => root.eventOpenRequested(event)
        }
    }

    NumberAnimation {
        id: agendaScroll
        target: agendaList
        property: "contentY"
        duration: 180
        easing.type: Easing.OutCubic
    }

    Text {
        anchors.centerIn: agendaList
        visible: root.agendaDays.length === 0
        text: "No events this month"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
    }

    Frame.PanelScrollIndicator {
        anchors {
            top: agendaList.top
            bottom: agendaList.bottom
            right: parent.right
        }
        flickable: agendaList
    }
}
