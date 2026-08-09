import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../theme"

RowLayout {
    id: root

    property bool hovered: hoverHandler.hovered
    readonly property var visibleWorkspaceIds: {
        const ids = new Set();
        const focusedId = Hyprland.focusedWorkspace?.id ?? -1;

        if (focusedId > 0)
            ids.add(focusedId);

        for (const workspace of Hyprland.workspaces.values) {
            const workspaceId = workspace?.id ?? -1;
            const windowCount = workspace?.lastIpcObject?.windows ?? 0;

            if (workspaceId > 0 && windowCount > 0)
                ids.add(workspaceId);
        }

        const sortedIds = Array.from(ids).sort((left, right) => left - right);
        return sortedIds.length > 0 ? sortedIds : [1];
    }

    spacing: 2

    HoverHandler {
        id: hoverHandler
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const workspaceEvents = ["openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2", "createworkspace", "destroyworkspace", "moveworkspace", "moveworkspacev2"];
            if (workspaceEvents.includes(event.name))
                Hyprland.refreshWorkspaces();
        }
    }

    Repeater {
        model: root.visibleWorkspaceIds

        Rectangle {
            id: button

            required property var modelData

            property int workspaceId: Number(modelData)
            property var workspace: Hyprland.workspaces.values.find(w => w.id === workspaceId)
            property bool active: Hyprland.focusedWorkspace?.id === workspaceId
            property bool hovered: workspaceMouse.containsMouse
            readonly property color surfaceColor: "transparent"

            Layout.preferredWidth: 22
            Layout.preferredHeight: 28

            radius: Theme.radius
            color: button.surfaceColor
            border.width: 0
            scale: 1

            Text {
                anchors.centerIn: parent

                text: button.workspaceId
                color: button.active || button.hovered ? Theme.fg : Theme.muted

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.bold: button.active
            }

            MouseArea {
                id: workspaceMouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + button.workspaceId + " })");
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

        }
    }
}
