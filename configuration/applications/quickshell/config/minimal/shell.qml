//@ pragma UseQApplication

import Quickshell
import "./modules/bar" as Bar
import "./modules/launcher" as Launcher
import "./modules/topleft" as TopLeft

ShellRoot {
    TopLeft.NotificationCenter {
        id: notificationCenter
    }

    Launcher.Init {}
    Bar.Init {
        id: bar

        notificationCenter: notificationCenter
    }
}
