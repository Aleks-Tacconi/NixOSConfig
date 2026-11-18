pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../wallpaper" as Wallpaper

/** In-session Wayland lockscreen using WlSessionLock and PAM. */
Scope {
    id: root

    readonly property int transitionDuration: 200
    property bool locked: false
    property bool unlocking: false
    property bool busy: false
    property string errorMessage: ""
    property string passwordText: ""
    property string pendingPassword: ""
    readonly property string username: Quickshell.env("USER") || "aleks"

    function lock(): void {
        if (root.locked)
            return;
        unlockTimer.stop();
        root.unlocking = false;
        root.errorMessage = "";
        root.passwordText = "";
        root.pendingPassword = "";
        root.busy = false;
        root.locked = true;
        pam.start();
    }

    function restartPam(): void {
        if (!root.locked || root.unlocking)
            return;
        if (pam.active)
            pam.abort();
        pam.start();
    }

    function submitPassword(password: string): void {
        if (root.busy || root.unlocking || password.length === 0)
            return;
        root.errorMessage = "";
        root.passwordText = "";
        root.busy = true;
        if (pam.responseRequired) {
            pam.respond(password);
        } else {
            root.pendingPassword = password;
            if (!pam.active)
                pam.start();
        }
    }

    IpcHandler {
        target: "lockscreen"

        function lock(): void {
            root.lock();
        }
    }

    Timer {
        id: unlockTimer

        interval: root.transitionDuration
        repeat: false
        onTriggered: {
            if (pam.active)
                pam.abort();
            root.locked = false;
            root.unlocking = false;
        }
    }

    PamContext {
        id: pam

        config: "login"
        user: root.username

        onResponseRequiredChanged: {
            if (pam.responseRequired && root.pendingPassword.length > 0) {
                const value = root.pendingPassword;
                root.pendingPassword = "";
                pam.respond(value);
            }
        }

        onCompleted: result => {
            root.busy = false;
            root.pendingPassword = "";
            if (result === PamResult.Success) {
                root.errorMessage = "";
                root.unlocking = true;
                unlockTimer.restart();
            } else {
                root.errorMessage = "Incorrect password";
                Qt.callLater(root.restartPam);
            }
        }

        onError: error => {
            root.busy = false;
            root.pendingPassword = "";
            root.errorMessage = "Authentication error";
            Qt.callLater(root.restartPam);
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: root.locked

        WlSessionLockSurface {
            color: "transparent"

            AuthSurface {
                anchors.fill: parent
                username: root.username
                wallpaperSource: Wallpaper.WallpaperService.current || Wallpaper.WallpaperService.fallback
                passwordText: root.passwordText
                errorMessage: root.errorMessage
                busy: root.busy
                showBackdrop: true
                revealed: !root.unlocking
                transitionDuration: root.transitionDuration
                onPasswordEdited: text => { root.passwordText = text; }
                onSubmitted: password => root.submitPassword(password)
            }
        }
    }
}
