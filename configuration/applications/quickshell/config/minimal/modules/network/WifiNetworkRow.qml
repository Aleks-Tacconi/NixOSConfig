import QtQuick
import QtQuick.Layouts
import "../frame" as Frame
import "../../theme"

/**
 * Clickable available-network row with signal and security details.
 */
Rectangle {
    id: root

    required property var network
    property bool pending: false
    property bool interactive: true

    signal activated

    readonly property bool hovered: mouseArea.containsMouse

    function signalIcon() {
        if (root.network.signal >= 75)
            return "󰤨";
        if (root.network.signal >= 50)
            return "󰤥";
        if (root.network.signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function detail() {
        if (root.pending)
            return "Connecting...";
        if (root.network.active)
            return "Connected";
        if (!root.network.supported)
            return "Enterprise · Setup in settings";
        if (root.network.savedUuid.length > 0)
            return `Saved · ${root.network.security}`;
        return root.network.security;
    }

    function actionIndicator() {
        if (root.network.active)
            return root.hovered ? "Disconnect" : "";
        if (!root.network.supported)
            return "↗";
        if (root.network.requiresPassword && root.network.savedUuid.length === 0)
            return "›";
        return "";
    }

    implicitHeight: 42
    radius: Theme.surfaceRadius
    opacity: root.pending ? 1.0 : (root.interactive ? 1.0 : 0.55)
    color: root.hovered && root.interactive ? Theme.panelSurfaceHover : (root.network.active ? Theme.panelSurface : "transparent")

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Theme.gap * 2
            rightMargin: Theme.gap * 2
        }
        spacing: Theme.gap * 2

        Text {
            Layout.preferredWidth: Theme.fontSize + 10
            text: root.signalIcon()
            color: root.network.active || root.hovered ? Theme.fg : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 2
            horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.network.ssid
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelMetaSize
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.detail()
                color: root.network.active ? Theme.fg : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelCaptionSize
                elide: Text.ElideRight
            }
        }

        Text {
            visible: root.network.requiresPassword
            text: "󰌾"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelMetaSize
        }

        Frame.PanelSpinner {
            visible: root.pending
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            spinnerSize: 14
        }

        Text {
            visible: !root.pending && root.actionIndicator().length > 0
            text: root.actionIndicator()
            color: (root.network.active && root.hovered) ? Theme.red : (root.hovered ? Theme.fg : Theme.muted)
            font.family: Theme.fontFamily
            font.pixelSize: (root.network.active && root.hovered) ? Theme.panelCaptionSize : Theme.panelMetaSize
        }

        Text {
            text: `${root.network.signal}%`
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.panelCaptionSize
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
