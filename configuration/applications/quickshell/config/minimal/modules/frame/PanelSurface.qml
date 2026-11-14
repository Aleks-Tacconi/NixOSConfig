pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Neutral dark popup surfaces and translucent bars with subtle edge shading. */
Rectangle {
    id: root

    property bool framed: true

    color: root.framed ? Theme.panelBg : Theme.bg
    radius: root.framed ? Theme.panelRadius : 0
    border.width: 0

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        color: "transparent"
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Theme.popupEdgeShade }
            GradientStop { position: 0.025; color: "transparent" }
            GradientStop { position: 0.975; color: "transparent" }
            GradientStop { position: 1; color: Theme.popupEdgeShade }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.popupEdgeShade }
            GradientStop { position: 0.025; color: "transparent" }
            GradientStop { position: 0.975; color: "transparent" }
            GradientStop { position: 1; color: Theme.popupEdgeShade }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        color: "transparent"
        radius: root.radius
        border.width: Theme.popupBorderWidth
        border.color: Theme.popupBorder
    }
}
