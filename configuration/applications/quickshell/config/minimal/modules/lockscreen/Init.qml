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

    property bool locked: false
    property bool busy: false
    property string errorMessage: ""
    property string pendingPassword: ""
    readonly property string username: Quickshell.env("USER") || "aleks"

    function lock(): void {
        if (root.locked)
            return;
        root.errorMessage = "";
        root.pendingPassword = "";
        root.busy = false;
        root.locked = true;
    }

    function submitPassword(password: string): void {
        root.errorMessage = "";
        root.busy = true;
        if (pam.responseRequired) {
            pam.respond(password);
        } else {
            root.pendingPassword = password;
        }
    }

    IpcHandler {
        target: "lockscreen"

        function lock(): void {
            root.lock();
        }
    }

    PamContext {
        id: pam

        config: "login"
        user: root.username
        active: root.locked

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
                root.locked = false;
            } else {
                root.errorMessage = "Incorrect password";
                if (root.locked) {
                    pam.active = false;
                    pam.active = true;
                }
            }
        }

        onError: error => {
            root.busy = false;
            root.pendingPassword = "";
            root.errorMessage = "Authentication error";
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: root.locked

        WlSessionLockSurface {
            AuthSurface {
                anchors.fill: parent
                username: root.username
                wallpaperSource: Wallpaper.WallpaperService.current
                errorMessage: root.errorMessage
                busy: root.busy
                onSubmitted: password => root.submitPassword(password)
            }
        }
    }
}
