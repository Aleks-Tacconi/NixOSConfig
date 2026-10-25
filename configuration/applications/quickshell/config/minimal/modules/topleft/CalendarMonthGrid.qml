pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../frame" as Frame

/** Month navigation and keyboard-accessible dates with compact selection marks. */
Column {
    id: root

    required property date month
    required property string selectedKey
    required property string todayKey
    required property var events
    readonly property int firstOffset: (new Date(root.month.getFullYear(), root.month.getMonth(), 1).getDay() + 6) % 7
    readonly property int dayCount: new Date(root.month.getFullYear(), root.month.getMonth() + 1, 0).getDate()
    readonly property int weekCount: Math.ceil((root.firstOffset + root.dayCount) / 7)
    signal dateSelected(string key)
    signal monthRequested(int delta)
    signal todayRequested

    spacing: Theme.panelItemGap

    /** Move keyboard selection across days and month boundaries. */
    function moveDay(day, offset) {
        const date = new Date(root.month.getFullYear(), root.month.getMonth(), day + offset);
        const key = Qt.formatDateTime(date, "yyyy-MM-dd");
        root.dateSelected(key);
        Qt.callLater(() => {
            const item = dates.itemAt(root.firstOffset + date.getDate() - 1);
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
        });
    }

    RowLayout {
        width: parent.width
        spacing: Theme.gap * 2

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Theme.surfaceRadius
            color: prevMonth.containsMouse ? Theme.panelSurfaceHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: "‹"
                color: prevMonth.containsMouse ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
            }

            MouseArea {
                id: prevMonth
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthRequested(-1)
            }
        }

        Text {
            Layout.fillWidth: true
            text: Qt.formatDateTime(root.month, "MMMM yyyy")
            horizontalAlignment: Text.AlignHCenter
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelTitleSize
            font.bold: true
        }

        Rectangle {
            Layout.preferredWidth: 54
            Layout.preferredHeight: 28
            radius: Theme.surfaceRadius
            color: todayBtn.containsMouse ? Theme.panelSurfaceHover : Theme.panelSurface

            Text {
                anchors.centerIn: parent
                text: "Today"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                font.bold: true
            }

            MouseArea {
                id: todayBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.todayRequested()
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
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthRequested(1)
            }
        }
    }

    Row {
        width: parent.width
        spacing: grid.columnSpacing

        Repeater {
            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            Text {
                required property string modelData
                width: (grid.width - grid.columnSpacing * 6) / 7
                text: modelData
                horizontalAlignment: Text.AlignHCenter
                color: Theme.muted
                opacity: 0.7
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
            }
        }
    }

    Grid {
        id: grid
        width: parent.width
        columns: 7
        rowSpacing: Theme.gap + 2
        columnSpacing: Theme.gap + 2

        Repeater {
            id: dates
            model: root.weekCount * 7

            Item {
                id: dayCell
                required property int index
                readonly property int day: dayCell.index - root.firstOffset + 1
                readonly property bool validDay: dayCell.day > 0 && dayCell.day <= root.dayCount
                readonly property string key: dayCell.validDay
                    ? Qt.formatDateTime(new Date(root.month.getFullYear(), root.month.getMonth(), dayCell.day), "yyyy-MM-dd") : ""
                readonly property bool selected: dayCell.validDay && dayCell.key === root.selectedKey
                readonly property bool today: dayCell.validDay && dayCell.key === root.todayKey
                readonly property bool hasEvents: root.events.some(event => event.date === dayCell.key)

                width: (grid.width - grid.columnSpacing * 6) / 7
                height: 30
                enabled: dayCell.validDay
                activeFocusOnTab: dayCell.validDay
                Accessible.role: Accessible.Button
                Accessible.name: dayCell.key
                Accessible.onPressAction: root.dateSelected(dayCell.key)
                Keys.onReturnPressed: root.dateSelected(dayCell.key)
                Keys.onEnterPressed: root.dateSelected(dayCell.key)
                Keys.onSpacePressed: root.dateSelected(dayCell.key)
                Keys.onLeftPressed: root.moveDay(dayCell.day, -1)
                Keys.onRightPressed: root.moveDay(dayCell.day, 1)
                Keys.onUpPressed: root.moveDay(dayCell.day, -7)
                Keys.onDownPressed: root.moveDay(dayCell.day, 7)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cardRadius
                    color: dayCell.selected ? Theme.fg : (dayCell.today ? Theme.panelSurfaceHover : (dayMouse.containsMouse && dayCell.validDay ? Theme.panelSurface : "transparent"))
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: dayCell.hasEvents ? -3 : 0
                        text: dayCell.validDay ? dayCell.day : ""
                        color: dayCell.selected ? "#121212" : (dayCell.today || (dayMouse.containsMouse && dayCell.validDay) || dayCell.hasEvents ? Theme.fg : Theme.muted)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        font.bold: dayCell.today || dayCell.selected
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        visible: dayCell.validDay && dayCell.hasEvents
                        width: 4
                        height: 4
                        radius: 2
                        color: dayCell.selected ? "#121212" : Theme.fg
                    }
                }

                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    enabled: dayCell.validDay
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.dateSelected(dayCell.key)
                }
            }
        }
    }
}
