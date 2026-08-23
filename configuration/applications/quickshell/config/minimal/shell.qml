//@ pragma UseQApplication

import Quickshell
import "./modules/bar" as Bar
import "./modules/launcher" as Launcher
import "./modules/network" as Network
import "./modules/topleft" as TopLeft

ShellRoot {
    Network.NetworkService {
        id: networkService
    }

    TopLeft.NotificationCenter {
        id: notificationCenter
    }

    Launcher.Init {}
    Bar.Init {
        id: bar

        notificationCenter: notificationCenter
        networkService: networkService
    }
}
