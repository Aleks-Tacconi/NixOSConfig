import QtQuick
import "../../theme"

Item {
    id: root

    property var events: []
    property date visibleMonth: new Date()
    property string selectedKey: Qt.formatDateTime(new Date(), "yyyy-MM-dd")

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

        Row {
            id: monthHeader

            width: parent.width
            height: 24
            spacing: Theme.gap * 3

            Text {
                width: 52
                anchors.verticalCenter: parent.verticalCenter
                text: "‹ Prev"
                color: previousMonth.containsMouse ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                font.bold: true

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
                width: parent.width - 52 - 56 - 52 - parent.spacing * 3
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(root.visibleMonth, "MMMM yyyy")
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelBodySize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: 56
                anchors.verticalCenter: parent.verticalCenter
                text: "Today"
                color: todayButton.containsMouse ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: todayButton

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.returnToToday()
                }
            }

            Text {
                width: 52
                anchors.verticalCenter: parent.verticalCenter
                text: "Next ›"
                color: nextMonth.containsMouse ? Theme.red : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                font.bold: true
                horizontalAlignment: Text.AlignRight

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
                    color: selected || dayMouse.containsMouse ? Theme.panelSurfaceHover : (today ? Theme.panelSurface : "transparent")
                    border.width: 0
                    radius: selected || today || dayMouse.containsMouse ? Theme.surfaceRadius : 0
                    opacity: currentMonthDay ? 1 : 0.22

                    Text {
                        id: dayNumber

                        anchors {
                            top: parent.top
                            left: parent.left
                        topMargin: 5
                        leftMargin: 5
                    }

                        text: parent.currentMonthDay ? String(parent.day).padStart(2, "0") : ""
                        color: parent.today || parent.eventDay || parent.selected ? Theme.red : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                        font.bold: parent.today || parent.selected
                    }

                    Text {
                        anchors {
                            left: parent.left
                            top: dayNumber.bottom
                            leftMargin: 5
                            topMargin: 1
                        }

                        visible: parent.eventDay
                        text: "󰃭 x" + parent.eventCount
                        color: Theme.fg
                        opacity: 0.82
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelCaptionSize
                        font.bold: true
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
            height: 112

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.darkRed
            }

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: Theme.gap * 2
                    leftMargin: Theme.gap * 2
                    rightMargin: Theme.gap * 2
                }

                spacing: Theme.gap

                Text {
                    width: parent.width
                    text: "Agenda"
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelTitleSize
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.selectedTitle()
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelMetaSize
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                Flickable {
                    id: agendaList

                    width: parent.width
                    height: 54
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
                            visible: !root.hasSelection || root.selectedEvents.length === 0
                            text: "No events"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelMetaSize
                        }

                        Repeater {
                            model: root.hasSelection ? root.selectedEvents : []

                            Text {
                                required property var modelData

                                width: parent.width
                                text: modelData.startTime.length > 0 ? `${modelData.startTime} // ${modelData.title}` : modelData.title
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelMetaSize
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }
        }
    }
}
