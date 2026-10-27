pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

/** Shared colors, typography, and spacing for the shell. */
QtObject {
    readonly property color bg: Qt.rgba(0, 0, 0, 0.7)
    readonly property color bg2: "#32000000"
    readonly property color onAccent: "#121212"
    readonly property color focusBorder: "#99FFFFFF"
    readonly property color accentColor: "#f2f2f2"
    readonly property color accentSurface: "#30000000"
    readonly property color fg: "#f2f2f2"
    readonly property color batteryCritical: "#ff5555"
    readonly property color muted: "#b0b0b0"
    readonly property color red: "#f2f2f2"
    readonly property color redTwo: "#d0d0d0"
    readonly property color darkRed: "#00000000"
    readonly property color panelBg: bg
    readonly property color panelSurface: Qt.rgba(0, 0, 0, 0.19)
    readonly property color panelSurfaceHover: Qt.rgba(0.08, 0.08, 0.08, 0.275)
    readonly property color launcherSelection: Qt.rgba(1, 1, 1, 0.1)
    readonly property color glassSurface: "#5C000000"
    readonly property color glassHighlight: "#08FFFFFF"
    readonly property color glassHighlightSoft: "#03FFFFFF"
    readonly property color glassShadow: "#70000000"
    readonly property color popupEdgeShade: "#20000000"
    readonly property color popupBorder: Qt.rgba(1, 1, 1, 0.14)
    readonly property color popupInnerEdge: "#44000000"
    readonly property color panelDivider: "#18FFFFFF"

    readonly property int barHeight: 44
    readonly property int frameSize: 0
    readonly property int frameOverlap: 0
    readonly property int dockFrameWidth: 0
    readonly property int radius: 6
    readonly property int gap: 4
    readonly property int panelRadius: 10
    readonly property int surfaceRadius: 6
    readonly property int cardRadius: 8
    readonly property int panelPadding: 14
    readonly property int panelRowHeight: 32
    readonly property int panelSectionGap: 16
    readonly property int panelItemGap: 8
    readonly property int popupGap: 10
    readonly property int popupDismissDelay: 320
    readonly property int popupBorderWidth: 1
    readonly property int popupShadowWidth: 1

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
    readonly property int emphasisWeight: Font.Bold
    readonly property int headingWeight: Font.Bold
    readonly property string monoFontFamily: "JetBrainsMono Nerd Font"
    readonly property int iconSize: 16
    readonly property int selectionMarkerWidth: 3
    readonly property int fontSize: 13
    readonly property int displaySize: 36
    readonly property int artworkSize: 88
    readonly property int panelTitleSize: fontSize
    readonly property int panelBodySize: fontSize
    readonly property int panelMetaSize: fontSize - 1
    readonly property int panelCaptionSize: fontSize - 2
}
