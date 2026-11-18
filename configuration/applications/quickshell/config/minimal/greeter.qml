//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland
import "./modules/lockscreen" as Lockscreen

/** Greetd login greeter sharing the lockscreen authentication surface. */
ShellRoot {
    id: root

    readonly property string username: Quickshell.env("QUICKSHELL_GREETER_USER") || "aleks"
    readonly property string wallpaperSource: Quickshell.env("QUICKSHELL_GREETER_WALLPAPER") || ""
    readonly property int transitionDuration: 180
    property bool busy: false
    property bool launching: false
    property string errorMessage: ""
    property string passwordText: ""
    property string pendingPassword: ""

    function startSession(): void {
        if (!Greetd.available || Greetd.state !== GreetdState.Inactive)
            return;
        Greetd.createSession(root.username);
    }

    function submitPassword(password: string): void {
        if (root.busy || root.launching || password.length === 0)
            return;
        root.errorMessage = "";
        root.passwordText = "";
        root.busy = true;
        if (Greetd.state === GreetdState.Authenticating) {
            Greetd.respond(password);
        } else {
            root.pendingPassword = password;
            root.startSession();
        }
    }

    function launchSession(): void {
        const cmd = Quickshell.env("QUICKSHELL_GREETER_CMD") || "start-hyprland";
        Greetd.launch([cmd]);
    }

    Component.onCompleted: root.startSession()

    Timer {
        id: launchTimer

        interval: root.transitionDuration
        repeat: false
        onTriggered: root.launchSession()
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) {
                root.busy = false;
                root.errorMessage = message || "Authentication failed";
                return;
            }
            if (responseRequired && root.pendingPassword.length > 0) {
                const value = root.pendingPassword;
                root.pendingPassword = "";
                Greetd.respond(value);
            }
        }

        function onAuthFailure(message) {
            root.busy = false;
            root.launching = false;
            root.pendingPassword = "";
            root.errorMessage = message || "Incorrect password";
            root.startSession();
        }

        function onReadyToLaunch() {
            root.launching = true;
            launchTimer.restart();
        }

        function onLaunched() {
            Qt.quit();
        }

        function onError(error) {
            root.busy = false;
            root.launching = false;
            root.pendingPassword = "";
            root.errorMessage = "Greeter error";
            root.startSession();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData

            screen: window.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Lockscreen.AuthSurface {
                anchors.fill: parent
                username: root.username
                wallpaperSource: root.wallpaperSource
                passwordText: root.passwordText
                errorMessage: root.errorMessage
                busy: root.busy
                showBackdrop: false
                revealed: !root.launching
                transitionDuration: root.transitionDuration
                onPasswordEdited: text => { root.passwordText = text; }
                onSubmitted: password => root.submitPassword(password)
            }
        }
    }
}
