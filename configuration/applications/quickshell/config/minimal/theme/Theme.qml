pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: "#42000000"
    readonly property color bg2: "#32000000"
    readonly property color fg: "#f2f2f2"
    readonly property color muted: "#b0b0b0"
    readonly property color red: "#f2f2f2"
    readonly property color redTwo: "#d0d0d0"
    readonly property color darkRed: "#00000000"
    readonly property color panelBg: "#66000000"
    readonly property color panelSurface: "#30000000"
    readonly property color panelSurfaceHover: "#46000000"
    readonly property color glassSurface: "#5C000000"
    readonly property color glassHighlight: "#08FFFFFF"
    readonly property color glassHighlightSoft: "#03FFFFFF"
    readonly property color glassShadow: "#70000000"
    readonly property color popupBorder: "#38FFFFFF"
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
    readonly property int popupBorderWidth: 1
    readonly property int popupShadowWidth: 1

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int panelTitleSize: fontSize
    readonly property int panelBodySize: fontSize
    readonly property int panelMetaSize: fontSize - 1
    readonly property int panelCaptionSize: fontSize - 2
}
