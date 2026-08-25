import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../frame" as Frame

Item {
    id: root

    property var events: []
    property date visibleMonth: new Date()
    property string selectedKey: Qt.formatDateTime(new Date(), "yyyy-MM-dd")

    signal eventOpenRequested(var event)

    readonly property int year: visibleMonth.getFullYear()
    readonly property int month: visibleMonth.getMonth()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var selectedEvents: eventsForDate(selectedKey)
    readonly property bool hasSelection: selectedKey.length > 0

    function changeMonth(delta) {
        root.visibleMonth = new Date(root.year, root.month + delta, 1);
        root.selectedKey = "";
    }

    function returnToToday() {
        const today = new Date();

        root.visibleMonth = today;
        root.selectedKey = Qt.formatDateTime(today, "yyyy-MM-dd");
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
            return "Select a day";

        const parts = root.selectedKey.split("-");
        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));

        return Qt.formatDateTime(date, "ddd d MMMM");
    }

    Column {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            id: monthHeader

            width: parent.width
            height: 30
            spacing: Theme.gap * 2

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
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
                font.pixelSize: Theme.panelBodySize + 1
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 28
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
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
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

        Item {
            width: 1
            height: Theme.gap
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
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Item {
            width: 1
            height: Theme.gap
        }

        Grid {
            id: calendarGrid

            width: parent.width
            height: parent.height - monthHeader.height - weekHeader.height - selectedStrip.height - Theme.gap * 2
            columns: 7
            rows: 6
            rowSpacing: Theme.gap
            columnSpacing: Theme.gap

            Repeater {
                model: 42

                Rectangle {
                    required property int index

                    readonly property int day: index - root.firstMondayOffset(root.year, root.month) + 1
                    readonly property bool currentMonthDay: day > 0 && day <= root.daysInMonth(root.year, root.month)
                    readonly property string key: currentMonthDay ? root.dateKey(day) : ""
                    readonly property bool today: key === Qt.formatDateTime(new Date(), "yyyy-MM-dd")
                    readonly property int eventCount: currentMonthDay ? root.eventCount(key) : 0
                    readonly property bool eventDay: eventCount > 0
                    readonly property bool selected: key.length > 0 && key === root.selectedKey

                    width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                    height: (calendarGrid.height - calendarGrid.rowSpacing * 5) / 6
                    clip: true
                    color: selected ? Theme.panelSurfaceHover : (dayMouse.containsMouse ? Theme.panelSurface : "transparent")
                    border.width: today && !selected ? 1 : 0
                    border.color: Theme.popupBorder
                    radius: Theme.cardRadius
                    opacity: currentMonthDay ? 1 : 0.22

                    Text {
                        id: dayNumber

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.eventDay ? -3 : 0
                        text: parent.currentMonthDay ? String(parent.day) : ""
                        color: parent.selected || parent.today ? Theme.fg : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        font.bold: parent.today || parent.selected
                    }

                    Row {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 5
                        }
                        visible: parent.eventDay
                        spacing: 3

                        Repeater {
                            model: Math.min(parent.parent.eventCount, 3)

                            Rectangle {
                                width: 3
                                height: 3
                                radius: 2
                                color: parent.parent.selected ? Theme.fg : Theme.redTwo
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
                        onClicked: root.selectedKey = parent.key
                    }
                }
            }
        }

        Item {
            id: selectedStrip

            width: parent.width
            height: 168

            Column {
                anchors {
                    fill: parent
                    topMargin: Theme.gap * 3
                }

                spacing: Theme.gap

                Frame.PanelGroupLabel {
                    id: selectedDayLabel

                    width: parent.width
                    title: root.selectedTitle()
                    detail: root.hasSelection
                        ? `${root.selectedEvents.length} ${root.selectedEvents.length === 1 ? "event" : "events"}`
                        : ""
                }

                Flickable {
                    id: agendaList

                    width: parent.width - Theme.gap * 2
                    height: parent.height - selectedDayLabel.height - parent.spacing
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: agendaEvents.implicitHeight
                    interactive: contentHeight > height

                    Connections {
                        target: root

                        function onSelectedKeyChanged() {
                            agendaList.contentY = 0;
                        }
                    }

                    Column {
                        id: agendaEvents

                        width: parent.width
                        spacing: Theme.gap

                        Text {
                            width: parent.width
                            height: 48
                            visible: root.hasSelection && root.selectedEvents.length === 0
                            text: "No events scheduled"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Repeater {
                            model: root.hasSelection ? root.selectedEvents : []

                            Rectangle {
                                id: eventRow

                                required property var modelData

                                width: parent.width
                                height: 48
                                radius: Theme.surfaceRadius
                                color: eventMouse.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface

                                Column {
                                    id: eventTime

                                    anchors {
                                        left: parent.left
                                        leftMargin: Theme.gap * 3
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 54
                                    spacing: 1

                                    Text {
                                        width: parent.width
                                        text: eventRow.modelData.startTime.length > 0 ? eventRow.modelData.startTime : "All day"
                                        color: Theme.redTwo
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelCaptionSize
                                        font.bold: true
                                    }

                                    Text {
                                        width: parent.width
                                        visible: eventRow.modelData.endTime.length > 0
                                        text: eventRow.modelData.endTime
                                        color: Theme.muted
                                        opacity: 0.7
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelCaptionSize
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
                                    text: eventRow.modelData.title
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelMetaSize
                                    font.weight: Font.Medium
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }

                                Text {
                                    id: eventArrow

                                    anchors {
                                        right: parent.right
                                        rightMargin: Theme.gap * 2
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: "↗"
                                    color: eventMouse.containsMouse ? Theme.fg : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.panelMetaSize
                                }

                                MouseArea {
                                    id: eventMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eventOpenRequested(eventRow.modelData)
                                }
                            }
                        }
                    }
                }

                Frame.PanelScrollIndicator {
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
    }
}
