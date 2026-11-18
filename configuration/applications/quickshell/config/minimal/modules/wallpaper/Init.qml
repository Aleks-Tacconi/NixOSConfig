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
            color: incoming.initialLoad ? "transparent" : Theme.onAccent
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
                    asynchronous: true
                    visible: !incoming.initialLoad && WallpaperService.previous.length > 0
                }

                Image {
                    id: incoming
                    property bool initialLoad: true
                    anchors.fill: parent
                    source: WallpaperService.current
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0
                    onSourceChanged: {
                        if (incoming.initialLoad)
                            return;
                        reveal.stop();
                        incoming.opacity = 0;
                    }
                    onStatusChanged: {
                        if (incoming.status === Image.Ready) {
                            if (incoming.initialLoad) {
                                incoming.initialLoad = false;
                                incoming.opacity = 1;
                                incoming.scale = 1;
                            } else {
                                reveal.restart();
                            }
                        } else if (incoming.status === Image.Error && incoming.initialLoad) {
                            incoming.initialLoad = false;
                        }
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
