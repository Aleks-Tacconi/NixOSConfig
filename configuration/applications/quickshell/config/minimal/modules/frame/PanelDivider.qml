import QtQuick
import "../../theme"

/**
 * Shared low-contrast divider for popup content sections.
 */
Rectangle {
    implicitWidth: 1
    implicitHeight: 1
    width: parent?.width ?? implicitWidth
    height: 1
    color: Theme.panelDivider
}
