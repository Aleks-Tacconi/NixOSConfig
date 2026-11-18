pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../theme"

/** Shared authentication surface used by both the lockscreen and greetd greeter. */
Item {
    id: root

    property string username: "aleks"
    property string wallpaperSource: ""
    property string passwordText: ""
    property string errorMessage: ""
    property bool busy: false
    property bool showPowerActions: true
    property bool showBackdrop: true
    property bool revealed: true
    property int transitionDuration: 200
    property bool entered: false
    property string currentTime: Qt.formatDateTime(new Date(), "HH:mm")
    property string currentDate: Qt.formatDateTime(new Date(), "dddd, MMMM d")

    readonly property bool windowActive: Window.active
    readonly property bool wallpaperReady: !root.showBackdrop
        || root.wallpaperSource.length === 0
        || wallpaper.status === Image.Ready
        || wallpaper.status === Image.Error
    readonly property bool visibleState: root.entered && root.revealed && root.wallpaperReady
    property real surfaceOpacity: root.visibleState ? 1 : 0

    signal submitted(string password)
    signal passwordEdited(string text)

    function focusInput(): void {
        if (!root.busy && root.revealed)
            passwordInput.forceActiveFocus();
    }

    Behavior on surfaceOpacity {
        NumberAnimation { duration: root.transitionDuration; easing.type: Easing.InOutCubic }
    }

    onBusyChanged: if (!root.busy) root.focusInput()
    onWindowActiveChanged: if (root.windowActive) root.focusInput()
    onPasswordTextChanged: {
        if (passwordInput.text !== root.passwordText) {
            passwordInput.text = root.passwordText;
            passwordInput.cursorPosition = passwordInput.text.length;
        }
    }
    onErrorMessageChanged: {
        if (root.errorMessage.length > 0)
            errorShake.restart();
    }
    Component.onCompleted: Qt.callLater(() => {
        root.entered = true;
        root.focusInput();
    })

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            root.currentTime = Qt.formatDateTime(now, "HH:mm");
            root.currentDate = Qt.formatDateTime(now, "dddd, MMMM d");
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.showBackdrop ? root.surfaceOpacity : 1

        Rectangle {
            anchors.fill: parent
            visible: root.showBackdrop
            color: Theme.onAccent
        }

        Image {
            id: wallpaper

            anchors.fill: parent
            source: root.wallpaperSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: root.wallpaperSource.length > 0 && wallpaper.status === Image.Ready
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceOpacity

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.focusInput()
        }

        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.visibleState ? 0 : 10
            }
            spacing: Theme.panelSectionGap * 1.5
            width: 340

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.displaySize * 1.6
                    font.weight: Theme.emphasisWeight
                    text: root.currentTime
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 1
                    text: root.currentDate
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.panelItemGap

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.panelRowHeight + 8
                    radius: Theme.surfaceRadius
                    color: Theme.bg
                    border.width: 1
                    border.color: root.errorMessage.length > 0
                        ? Theme.batteryCritical
                        : (passwordInput.activeFocus ? Theme.focusBorder : Theme.popupBorder)

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    transform: Translate {
                        id: shakeOffset
                        x: 0
                    }

                    SequentialAnimation {
                        id: errorShake
                        NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 45; easing.type: Easing.OutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 8; duration: 55; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: -5; duration: 50; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 4; duration: 45; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 45; easing.type: Easing.OutQuad }
                    }

                    TextInput {
                        id: passwordInput

                        anchors {
                            fill: parent
                            leftMargin: Theme.panelItemGap + 2
                            rightMargin: Theme.panelItemGap + 2
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelBodySize
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        enabled: !root.busy && root.revealed
                        focus: true

                        onTextEdited: root.passwordEdited(passwordInput.text)
                        onAccepted: {
                            if (root.busy || !root.revealed || passwordInput.text.length === 0)
                                return;
                            const value = passwordInput.text;
                            passwordInput.text = "";
                            root.passwordEdited("");
                            root.submitted(value);
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: passwordInput.text.length === 0
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelMetaSize
                        text: root.busy ? "Authenticating..." : "Password"
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: opacity > 0
                    opacity: root.errorMessage.length > 0 ? 1 : 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Theme.batteryCritical
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelCaptionSize
                    text: root.errorMessage

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
            }
        }

        PowerActions {
            visible: root.showPowerActions
            interactive: root.revealed && !root.busy
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Theme.panelPadding * 1.5
            }
        }
    }
}
