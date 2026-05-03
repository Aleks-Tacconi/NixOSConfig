import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.dock
import qs.modules.ii.overview
import qs.modules.ii.sidebarLeft
import qs.modules.ii.wallpaperSelector

Scope {
    PanelLoader { component: Background {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: WallpaperSelector {} }
}
