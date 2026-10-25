pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/** Load emoji search data on first use rather than embedding it in the view. */
Scope {
    id: root

    property bool active: false
    property var items: []

    FileView {
        path: Qt.resolvedUrl("emoji.json")
        preload: root.active
        onLoaded: root.items = JSON.parse(text()).map(emoji => ({
            kind: "emoji",
            title: root.title(emoji[1]),
            subtitle: "Copy emoji",
            glyph: emoji[0],
            value: emoji[0],
            search: emoji.join(" ").toLowerCase()
        }))
    }

    /** Remove category suffixes from an emoji's readable name. */
    function title(text) {
        const cleaned = text.replace(/\s+(smileys and emotion|people and body|animals and nature|food and drink|travel and places|activities|objects|symbols|flags)\b.*/i, "").trim();
        return (cleaned || text.trim()).replace(/\b\w/g, letter => letter.toUpperCase());
    }
}
