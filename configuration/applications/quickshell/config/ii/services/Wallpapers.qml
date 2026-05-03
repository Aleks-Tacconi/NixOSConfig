import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property string wallpaperDir: "/home/aleks/wallpapers"
    property string thumbnailDir: "/tmp/quickshell-wallpaper-thumbs"
    property var wallpapers: []
    property var extensions: ["jpg", "jpeg", "png", "gif", "webp", "avif", "bmp", "svg"]

    signal changed()
    signal filesLoaded()

    function isImageFile(name: string): bool {
        const lower = name.toLowerCase()

        for (const ext of root.extensions) {
            if (lower.endsWith(`.${ext}`)) {
                return true
            }
        }

        return false
    }

    function loadWallpapers() {
        loadProc.running = false
        loadProc.running = true
    }

    Process {
        id: loadProc
        command: ["bash", "-c", `
            mkdir -p '${root.thumbnailDir}'
            cd '${root.wallpaperDir}' && ls -1
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text
                    .split("\n")
                    .map(s => s.trim())
                    .filter(s => s.length > 0)

                const found = []

                for (const line of lines) {
                    if (root.isImageFile(line)) {
                        found.push(`${root.wallpaperDir}/${line}`)
                    }
                }

                root.wallpapers = found
                root.updateWallpapersModel()
                root.filesLoaded()
            }
        }
    }

    ListModel {
        id: wallpapersListModel
    }

    function thumbnailPath(path) {
        const safeName = path
            .split("/").join("_")
            .split(" ").join("_")
            .split(":").join("_")

        return `${root.thumbnailDir}/${safeName}.jpg`
    }

    function updateWallpapersModel() {
        wallpapersListModel.clear()

        for (const path of root.wallpapers) {
            const name = path.split("/").pop()
            const thumb = root.thumbnailPath(path)

            wallpapersListModel.append({
                fileName: name,
                filePath: path,
                fileUrl: `file://${encodeURI(thumb)}`,
                originalFileUrl: `file://${encodeURI(path)}`,
                fileIsDir: false
            })
        }

        thumbnailProc.running = false
        thumbnailProc.running = true
    }

    Process {
        id: thumbnailProc
        command: ["bash", "-c", `
            mkdir -p '${root.thumbnailDir}'

            for img in '${root.wallpaperDir}'/*; do
                [ -f "$img" ] || continue

                case "$img" in
                    *.jpg|*.jpeg|*.png|*.gif|*.webp|*.avif|*.bmp|*.svg|*.JPG|*.JPEG|*.PNG|*.GIF|*.WEBP|*.AVIF|*.BMP|*.SVG)
                        safe="$(printf "%s" "$img" | sed 's#/#_#g; s# #_#g; s#:#_#g')"
                        thumb='${root.thumbnailDir}'/"$safe.jpg"

                        if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
                            magick "$img[0]" -thumbnail 420x315^ -gravity center -extent 420x315 "$thumb"
                        fi
                        ;;
                esac
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                root.updateWallpapersModelOnly()
                root.filesLoaded()
            }
        }
    }

    function updateWallpapersModelOnly() {
        wallpapersListModel.clear()

        for (const path of root.wallpapers) {
            const name = path.split("/").pop()
            const thumb = root.thumbnailPath(path)

            wallpapersListModel.append({
                fileName: name,
                filePath: path,
                fileUrl: `file://${encodeURI(thumb)}`,
                originalFileUrl: `file://${encodeURI(path)}`,
                fileIsDir: false
            })
        }
    }

    function getWallpapersModel() {
        return wallpapersListModel
    }

    Process {
        id: applyProc
    }

    function openFallbackPicker() {
        applyProc.exec([
            Directories.wallpaperSwitchScriptPath,
            "--no-gnome"
        ])
    }

    function apply(path) {
        if (!path || path.length === 0) {
            return
        }

        const wallpaperPath = FileUtils.trimFileProtocol(path)

        applyProc.exec([
            Directories.wallpaperSwitchScriptPath,
            "--image", wallpaperPath,
            "--no-gnome"
        ])

        root.changed()
    }

    function select(path) {
        root.apply(path)
    }

    function randomFromCurrentFolder() {
        if (root.wallpapers.length === 0) {
            return
        }

        const idx = Math.floor(Math.random() * root.wallpapers.length)
        const path = root.wallpapers[idx]

        root.select(path)
    }

    IpcHandler {
        target: "wallpapers"

        function apply(path: string): void {
            root.apply(path)
        }
    }

    Component.onCompleted: {
        root.loadWallpapers()
    }
}
