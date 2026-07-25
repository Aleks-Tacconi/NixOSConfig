/**
 * Returns a scaled size that fits within the provided bounds.
 */
function scaleWindow(hyprlandClient, maxWindowWidth, maxWindowHeight) {
    if (!hyprlandClient || !hyprlandClient.size)
        return Qt.size(maxWindowWidth, maxWindowHeight)

    const [width, height] = hyprlandClient.size
    const scale = Math.min(maxWindowWidth / width, maxWindowHeight / height)

    return Qt.size(width * scale, height * scale)
}
