import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../frame" as Frame

Item {
    id: root

    property var events: []
    property date visibleMonth: new Date()
    property string selectedKey: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    property date clockNow: new Date()

    signal eventOpenRequested(var event)

    readonly property string todayKey: Qt.formatDateTime(clockNow, "yyyy-MM-dd")
    readonly property int year: visibleMonth.getFullYear()
    readonly property int month: visibleMonth.getMonth()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var selectedEvents: eventsForDate(selectedKey)
    readonly property bool hasSelection: selectedKey.length > 0
    readonly property var scheduleDays: buildScheduleDays(events, visibleMonth)

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.clockNow = new Date()
    }

    onVisibleChanged: {
        if (root.visible) {
            root.returnToToday();
        }
    }

    function changeMonth(delta) {
        root.visibleMonth = new Date(root.year, root.month + delta, 1);
        root.selectedKey = "";
        Qt.callLater(() => {
            agendaList.contentY = 0;
        });
    }

    function returnToToday() {
        const today = new Date();

        root.visibleMonth = today;
        root.selectedKey = Qt.formatDateTime(today, "yyyy-MM-dd");
        Qt.callLater(() => root.scrollToDate(root.selectedKey, false));
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstMondayOffset(year, month) {
        const sundayBased = new Date(year, month, 1).getDay();

        return (sundayBased + 6) % 7;
    }

    function dateKey(day) {
        const date = new Date(root.year, root.month, day);

        return Qt.formatDateTime(date, "yyyy-MM-dd");
    }

    function eventsForDate(key) {
        return root.events.filter(item => item.date === key);
    }

    function hasEvent(key) {
        return root.events.some(item => item.date === key);
    }

    function eventCount(key) {
        return root.eventsForDate(key).length;
    }

    function selectedTitle() {
        if (!root.hasSelection)
            return Qt.formatDateTime(root.visibleMonth, "MMMM yyyy");

        const parts = root.selectedKey.split("-");
        if (parts.length < 3)
            return Qt.formatDateTime(root.visibleMonth, "MMMM yyyy");

        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));

        return Number.isNaN(date.getTime()) ? Qt.formatDateTime(root.visibleMonth, "MMMM yyyy") : Qt.formatDateTime(date, "ddd d MMMM");
    }

    NumberAnimation {
        id: agendaScrollAnim

        target: agendaList
        property: "contentY"
        duration: 240
        easing.type: Easing.OutCubic
    }

    function scrollToDate(key, animate) {
        if (!key || key.length === 0)
            return;

        if (animate === undefined)
            animate = true;

        const list = root.scheduleDays ?? [];
        for (let i = 0; i < list.length; ++i) {
            if (list[i].dateKey === key) {
                agendaScrollAnim.stop();
                if (animate) {
                    const item = agendaList.itemAtIndex(i);
                    if (item) {
                        agendaScrollAnim.from = agendaList.contentY;
                        agendaScrollAnim.to = Math.max(0, Math.min(item.y, Math.max(0, agendaList.contentHeight - agendaList.height)));
                        agendaScrollAnim.start();
                        return;
                    }
                }
                agendaList.positionViewAtIndex(i, ListView.Beginning);
                return;
            }
        }
    }

    function buildScheduleDays(eventsList, monthDate) {
        const dayMap = {};
        const now = root.clockNow;
        const todayStr = Qt.formatDateTime(now, "yyyy-MM-dd");
        const year = monthDate.getFullYear();
        const month = monthDate.getMonth();
        const numDays = root.daysInMonth(year, month);
        const viewPrefix = Qt.formatDateTime(monthDate, "yyyy-MM");

        for (let d = 1; d <= numDays; ++d) {
            const dayKey = `${viewPrefix}-${String(d).padStart(2, "0")}`;
            dayMap[dayKey] = [];
        }

        if (eventsList && eventsList.length > 0) {
            for (let i = 0; i < eventsList.length; ++i) {
                const ev = eventsList[i];
                if (!ev || !ev.date)
                    continue;

                if (ev.date.startsWith(viewPrefix)) {
                    if (!dayMap[ev.date])
                        dayMap[ev.date] = [];
                    dayMap[ev.date].push(ev);
                }
            }
        }

        const sortedKeys = Object.keys(dayMap).sort();
        const result = [];

        for (let k = 0; k < sortedKeys.length; ++k) {
            const key = sortedKeys[k];
            const parts = key.split("-");
            if (parts.length < 3)
                continue;

            const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
            const isToday = key === todayStr;
            const evs = dayMap[key] || [];

            evs.sort((a, b) => {
                if (!a.startTime && b.startTime) return -1;
                if (a.startTime && !b.startTime) return 1;
                return (a.startTime || "").localeCompare(b.startTime || "");
            });

            let nowInsertIndex = 0;
            if (isToday) {
                for (let e = 0; e < evs.length; ++e) {
                    if (evs[e].endAt && evs[e].endAt < now)
                        nowInsertIndex = e + 1;
                }
            }

            result.push({
                dateKey: key,
                date: date,
                isToday: isToday,
                formattedHeader: Qt.formatDateTime(date, "ddd, d MMM"),
                events: evs,
                nowInsertIndex: nowInsertIndex
            });
        }

        return result;
    }

    onEventsChanged: {
        Qt.callLater(() => {
            root.scrollToDate(root.selectedKey, false);
        });
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            root.scrollToDate(root.selectedKey, false);
        });
    }

    Column {
        id: monthSection

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Theme.gap

        RowLayout {
            id: monthHeader

            width: parent.width
            height: 28
            spacing: Theme.gap * 2

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.surfaceRadius
                color: previousMonth.containsMouse ? Theme.panelSurfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: previousMonth.containsMouse ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                }

                MouseArea {
                    id: previousMonth

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.changeMonth(-1)
                }
            }

            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(root.visibleMonth, "MMMM yyyy")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 26
                radius: Theme.surfaceRadius
                color: todayButton.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface

                Text {
                    anchors.centerIn: parent
                    text: "Today"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    font.bold: true
                }

                MouseArea {
                    id: todayButton

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.returnToToday()
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.surfaceRadius
                color: nextMonth.containsMouse ? Theme.panelSurfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: nextMonth.containsMouse ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 3
                }

                MouseArea {
                    id: nextMonth

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.changeMonth(1)
                }
            }
        }

        Row {
            id: weekHeader

            width: parent.width
            height: 16

            Repeater {
                model: root.dayLabels

                Text {
                    required property string modelData

                    width: parent.width / 7
                    text: modelData
                    color: Theme.muted
                    opacity: 0.65
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Grid {
            id: calendarGrid

            width: parent.width
            height: 204
            columns: 7
            rows: 6
            rowSpacing: Theme.gap + 1
            columnSpacing: Theme.gap + 1

            Repeater {
                model: 42

                Rectangle {
                    id: dayCell

                    required property int index

                    readonly property int day: index - root.firstMondayOffset(root.year, root.month) + 1
                    readonly property bool currentMonthDay: day > 0 && day <= root.daysInMonth(root.year, root.month)
                    readonly property string key: currentMonthDay ? root.dateKey(day) : ""
                    readonly property bool today: key === root.todayKey
                    readonly property int eventCount: currentMonthDay ? root.eventCount(key) : 0
                    readonly property bool eventDay: eventCount > 0
                    readonly property bool selected: key.length > 0 && key === root.selectedKey

                    width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                    height: (calendarGrid.height - calendarGrid.rowSpacing * 5) / 6
                    clip: true
                    color: today ? Theme.panelSurfaceHover : (dayMouse.containsMouse && currentMonthDay ? Theme.panelSurface : "transparent")
                    border.width: 0
                    radius: Theme.cardRadius
                    opacity: currentMonthDay ? 1 : 0.22

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: selectionPill

                        anchors.fill: parent
                        radius: Theme.cardRadius
                        color: Theme.fg
                        opacity: dayCell.selected ? 1 : 0
                        scale: dayCell.selected ? 1.0 : 0.72

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    Text {
                        id: dayNumber

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.eventDay ? -4 : 0
                        text: parent.currentMonthDay ? String(parent.day) : ""
                        color: parent.selected ? "#121212" : (parent.today ? Theme.fg : (parent.currentMonthDay ? (dayMouse.containsMouse || parent.eventDay ? Theme.fg : Theme.muted) : Theme.muted))
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        font.bold: parent.today || parent.selected

                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 4
                        }
                        visible: parent.eventDay && parent.currentMonthDay
                        spacing: 2.5

                        Repeater {
                            model: Math.min(dayCell.eventCount, 3)

                            Rectangle {
                                width: 3
                                height: 3
                                radius: 1.5
                                color: dayCell.selected ? "#121212" : (dayCell.today ? Theme.fg : Theme.redTwo)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 160
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: dayMouse

                        anchors.fill: parent
                        enabled: parent.currentMonthDay
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.selectedKey = parent.key;
                            Qt.callLater(() => root.scrollToDate(parent.key, true));
                        }
                    }
                }
            }
        }
    }

    Frame.PanelDivider {
        id: divider

        anchors {
            top: monthSection.bottom
            topMargin: Theme.gap * 2
            left: parent.left
            right: parent.right
        }
        fullWidth: true
    }

    Item {
        id: scheduleSection

        anchors {
            top: divider.bottom
            topMargin: Theme.gap * 2
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Rectangle {
            visible: (root.scheduleDays?.length ?? 0) === 0
            anchors {
                top: parent.top
                topMargin: Theme.gap
                left: parent.left
                right: parent.right
            }
            height: 48
            radius: Theme.surfaceRadius
            color: Theme.panelSurface
            border.width: 0

            Text {
                anchors.centerIn: parent
                text: "No events scheduled this month"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
            }
        }

        ListView {
            id: agendaList

            visible: (root.scheduleDays?.length ?? 0) > 0
            anchors {
                top: parent.top
                left: parent.left
                right: scrollIndicator.left
                rightMargin: Theme.gap
                bottom: parent.bottom
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: Theme.gap * 2
            model: root.scheduleDays
            cacheBuffer: 2000

            onMovementStarted: agendaScrollAnim.stop()

            onContentYChanged: {
                if (agendaList.moving || agendaList.flicking) {
                    if (agendaList.atYBeginning && (root.scheduleDays?.length ?? 0) > 0) {
                        const firstDay = root.scheduleDays[0];
                        if (firstDay && firstDay.dateKey && firstDay.dateKey !== root.selectedKey)
                            root.selectedKey = firstDay.dateKey;
                        return;
                    }
                    if (agendaList.atYEnd && (root.scheduleDays?.length ?? 0) > 0) {
                        const lastDay = root.scheduleDays[root.scheduleDays.length - 1];
                        if (lastDay && lastDay.dateKey && lastDay.dateKey !== root.selectedKey)
                            root.selectedKey = lastDay.dateKey;
                        return;
                    }
                    const idx = agendaList.indexAt(20, agendaList.contentY + 14);
                    if (idx >= 0 && idx < root.scheduleDays.length) {
                        const day = root.scheduleDays[idx];
                        if (day && day.dateKey && day.dateKey !== root.selectedKey) {
                            root.selectedKey = day.dateKey;
                        }
                    }
                }
            }

            component NowIndicator: Item {
                width: parent.width
                height: 18

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Theme.gap
                        rightMargin: Theme.gap
                    }
                    spacing: Theme.gap * 1.5

                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: Theme.fg
                    }

                    Text {
                        text: Qt.formatDateTime(root.clockNow, "hh:mm") + " · Now"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.panelDivider
                        opacity: 0.6
                    }
                }
            }

            delegate: Item {
                id: dayBlock

                required property var modelData
                required property int index

                readonly property string dateKey: modelData.dateKey
                readonly property bool isToday: modelData.isToday
                readonly property var dayEvents: modelData.events

                width: ListView.view.width
                implicitHeight: dayColumn.implicitHeight + Theme.gap
                height: implicitHeight

                Column {
                    id: dayColumn

                    width: parent.width
                    spacing: Theme.gap

                    Rectangle {
                        visible: dayBlock.index > 0
                        width: parent.width
                        height: 1
                        color: Theme.panelDivider
                        opacity: 0.4
                    }

                    Item {
                        id: dayHeader

                        width: parent.width
                        height: 22

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Theme.gap
                                rightMargin: Theme.gap
                            }
                            spacing: Theme.gap * 1.5

                            Rectangle {
                                visible: dayBlock.isToday
                                Layout.preferredWidth: 5
                                Layout.preferredHeight: 5
                                radius: 2.5
                                color: Theme.fg
                            }

                            Text {
                                text: dayBlock.modelData.formattedHeader
                                color: dayBlock.isToday ? Theme.fg : Theme.muted
                                opacity: dayBlock.isToday ? 1.0 : 0.72
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                font.weight: dayBlock.isToday ? Font.Bold : Font.Medium
                            }

                            Rectangle {
                                visible: dayBlock.isToday
                                Layout.preferredHeight: 16
                                Layout.preferredWidth: todayLabel.implicitWidth + Theme.gap * 2
                                radius: 3
                                color: Theme.panelSurfaceHover
                                border.width: 1
                                border.color: Theme.popupBorder

                                Text {
                                    id: todayLabel
                                    anchors.centerIn: parent
                                    text: "Today"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelCaptionSize - 1
                                    font.bold: true
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: dayBlock.dayEvents.length > 0
                                text: `${dayBlock.dayEvents.length} ${dayBlock.dayEvents.length === 1 ? "event" : "events"}`
                                color: Theme.muted
                                opacity: 0.55
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelCaptionSize
                            }
                        }
                    }

                    NowIndicator {
                        visible: dayBlock.isToday && dayBlock.modelData.nowInsertIndex === 0
                    }

                    Rectangle {
                        visible: dayBlock.dayEvents.length === 0
                        width: parent.width
                        height: 30
                        radius: Theme.surfaceRadius
                        color: Theme.panelSurface
                        opacity: 0.45

                        Text {
                            anchors.centerIn: parent
                            text: "No events scheduled"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelCaptionSize
                        }
                    }

                    Repeater {
                        model: dayBlock.dayEvents

                        Column {
                            id: eventEntry

                            required property var modelData
                            required property int index

                            readonly property bool isPast: (dayBlock.modelData.dateKey < root.todayKey) || (dayBlock.isToday && modelData.endAt !== null && modelData.endAt < root.clockNow)
                            readonly property bool isOngoing: dayBlock.isToday && modelData.startTime.length > 0 && modelData.startAt !== null && modelData.endAt !== null && modelData.startAt <= root.clockNow && root.clockNow <= modelData.endAt

                            width: dayColumn.width
                            spacing: Theme.gap

                            Rectangle {
                                id: eventRow

                                width: parent.width
                                height: 42
                                radius: Theme.surfaceRadius
                                color: eventMouse.containsMouse ? Theme.panelSurfaceHover : (eventEntry.isOngoing ? Theme.panelSurfaceHover : Theme.panelSurface)
                                border.width: eventEntry.isOngoing ? 1 : 0
                                border.color: Theme.popupBorder
                                opacity: eventEntry.isPast ? 0.6 : 1.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    visible: eventEntry.isOngoing
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        margins: 4
                                    }
                                    width: 3
                                    radius: 1.5
                                    color: Theme.fg
                                }

                                Column {
                                    id: eventTime

                                    anchors {
                                        left: parent.left
                                        leftMargin: eventEntry.isOngoing ? Theme.gap * 3.5 : Theme.gap * 2.5
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 58
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: eventEntry.modelData.startTime.length > 0 ? eventEntry.modelData.startTime : "All day"
                                        color: eventEntry.isOngoing ? Theme.fg : (eventEntry.modelData.startTime.length > 0 ? Theme.redTwo : Theme.muted)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelCaptionSize
                                        font.bold: eventEntry.isOngoing || eventEntry.modelData.startTime.length > 0
                                    }

                                    Text {
                                        width: parent.width
                                        visible: eventEntry.modelData.endTime.length > 0
                                        text: eventEntry.modelData.endTime
                                        color: Theme.muted
                                        opacity: 0.7
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelCaptionSize - 1
                                    }
                                }

                                Text {
                                    anchors {
                                        left: eventTime.right
                                        right: eventArrow.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: Theme.gap * 2
                                        rightMargin: Theme.gap * 2
                                    }
                                    text: eventEntry.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelMetaSize
                                    font.weight: eventEntry.isOngoing ? Font.Bold : Font.Medium
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    id: eventArrow

                                    anchors {
                                        right: parent.right
                                        rightMargin: Theme.gap * 2.5
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: "↗"
                                    color: eventMouse.containsMouse ? Theme.fg : Theme.muted
                                    opacity: eventMouse.containsMouse ? 1.0 : 0.4
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelMetaSize

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                }

                                MouseArea {
                                    id: eventMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eventOpenRequested(eventEntry.modelData)
                                }
                            }

                            NowIndicator {
                                visible: dayBlock.isToday && (eventEntry.index + 1) === dayBlock.modelData.nowInsertIndex
                            }
                        }
                    }
                }
            }
        }
        Frame.PanelScrollIndicator {
            id: scrollIndicator

            anchors {
                top: agendaList.top
                right: parent.right
                bottom: agendaList.bottom
                rightMargin: 1
            }
            flickable: agendaList
        }
    }
}
