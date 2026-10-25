pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Group agenda events beneath one date label, without nested cards or badges. */
Column {
    id: root

    required property var day
    required property date now
    signal eventOpenRequested(var event)

    spacing: Theme.gap * 1.5

    Text {
        width: parent.width
        leftPadding: Theme.gap * 2
        bottomPadding: 2
        text: root.day.isToday ? `Today · ${root.day.formattedHeader}` : root.day.formattedHeader
        color: root.day.isToday ? Theme.fg : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelMetaSize
        font.bold: root.day.isToday
    }

    Rectangle {
        visible: root.day.events.length === 0
        width: parent.width
        height: 32
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
        model: root.day.events

        CalendarAgendaEvent {
            required property var modelData
            width: root.width
            height: implicitHeight
            event: modelData
            now: root.now
            onActivated: root.eventOpenRequested(modelData)
        }
    }
}
