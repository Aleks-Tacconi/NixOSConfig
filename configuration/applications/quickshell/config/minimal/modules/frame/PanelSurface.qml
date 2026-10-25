pragma ComponentBehavior: Bound

import QtQuick
import "../../theme"

/** Translucent glass surface with subtle borders and highlights. */
Rectangle {
    id: root

    property bool framed: true

    color: root.framed ? Theme.panelBg : Theme.bg
    radius: root.framed ? Theme.panelRadius : 0
    border.width: root.framed ? Theme.popupBorderWidth : 0
    border.color: Theme.popupBorder

    Rectangle {
        anchors {
            fill: parent
            margins: Theme.popupBorderWidth
        }
        visible: root.framed
        color: "transparent"
        radius: Math.max(0, root.radius - Theme.popupBorderWidth)
        border.color: Theme.popupInnerEdge
        border.width: Theme.popupShadowWidth
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0
                color: root.framed ? Theme.glassHighlight : Theme.glassHighlightSoft
            }

            GradientStop {
                position: root.framed ? 0.34 : 0.55
                color: root.framed ? Theme.glassHighlightSoft : "transparent"
            }

            GradientStop {
                position: 1
                color: Theme.glassShadow
            }
        }
    }
}
