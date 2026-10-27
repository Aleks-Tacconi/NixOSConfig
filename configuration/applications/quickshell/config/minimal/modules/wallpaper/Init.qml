pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"

/** Render a crossfading, gently zooming wallpaper behind each desktop. */
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: desktop
            required property var modelData
            screen: desktop.modelData
            color: Theme.onAccent
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            mask: Region {}

            Item {
                anchors.fill: parent
                clip: true

                Image {
                    anchors.fill: parent
                    source: WallpaperService.previous
                    fillMode: Image.PreserveAspectCrop
                }

                Image {
                    id: incoming
                    anchors.fill: parent
                    source: WallpaperService.current
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0
                    onSourceChanged: {
                        reveal.stop();
                        incoming.opacity = 0;
                    }
                    onStatusChanged: {
                        if (incoming.status === Image.Ready)
                            reveal.restart();
                    }

                    ParallelAnimation {
                        id: reveal
                        NumberAnimation {
                            target: incoming
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 700
                            easing.type: Easing.InOutCubic
                        }
                        NumberAnimation {
                            target: incoming
                            property: "scale"
                            from: 1.035
                            to: 1
                            duration: 850
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
