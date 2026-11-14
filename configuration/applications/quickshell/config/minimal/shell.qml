//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import Quickshell
import "./modules/bar" as Bar
import "./modules/wallpaper" as Wallpaper
import "./modules/launcher" as Launcher
import "./modules/lockscreen" as Lockscreen
import "./modules/network" as Network
import "./modules/topleft" as TopLeft

ShellRoot {
    Network.NetworkService {
        id: networkBackend
    }

    TopLeft.NotificationCenter {
        id: notificationService
    }

    Wallpaper.Init {}
    Launcher.Init {}
    Lockscreen.Init {}
    Bar.Init {
        id: bar

        notificationCenter: notificationService
        networkService: networkBackend
    }
}
