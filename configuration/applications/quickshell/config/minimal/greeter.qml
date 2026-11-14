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
    property bool busy: false
    property string errorMessage: ""
    property string pendingPassword: ""

    function startSession(): void {
        if (!Greetd.available)
            return;
        Greetd.createSession(root.username);
    }

    function submitPassword(password: string): void {
        root.errorMessage = "";
        root.busy = true;
        if (Greetd.state === GreetdState.Authenticating) {
            Greetd.respond(password);
        } else {
            root.pendingPassword = password;
            root.startSession();
        }
    }

    Component.onCompleted: root.startSession()

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
            root.pendingPassword = "";
            root.errorMessage = message || "Incorrect password";
            root.startSession();
        }

        function onReadyToLaunch() {
            const cmd = Quickshell.env("QUICKSHELL_GREETER_CMD") || "start-hyprland";
            Greetd.launch([cmd]);
        }

        function onError(error) {
            root.busy = false;
            root.pendingPassword = "";
            root.errorMessage = "Greeter error";
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
                errorMessage: root.errorMessage
                busy: root.busy
                onSubmitted: password => root.submitPassword(password)
            }
        }
    }
}
