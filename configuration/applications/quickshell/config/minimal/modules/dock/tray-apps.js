/** Normalize application identifiers without guessing app-specific aliases. */
function normalized(value) {
    return String(value || "").toLowerCase().replace(/\.desktop$/, "").trim();
}

/** Remove instance suffixes used by status-notifier and GTK tray implementations. */
function trayIdentifier(value) {
    return normalized(value).replace(/(?:[-_]status[-_]icon)?[-_]\d+$/, "");
}

/** Compare desktop IDs and their reverse-domain short names. */
function identifiers(value) {
    const key = normalized(value);
    return key ? [key, key.split(".").pop()] : [];
}

/** Find a unique desktop entry using tray identity, then its display title. */
function desktopEntryForTray(item, entries) {
    if (!item)
        return null;
    const id = trayIdentifier(item.id);
    const matches = entries.filter(entry => {
        const keys = identifiers(entry.id).concat(identifiers(entry.startupClass));
        return keys.includes(id);
    });
    if (matches.length === 1)
        return matches[0];
    const title = normalized(item.title);
    if (title.length > 0) {
        const exactNames = entries.filter(entry =>
            normalized(entry.name) === title || identifiers(entry.id).includes(title));
        if (exactNames.length === 1)
            return exactNames[0];
        const prefixNames = entries.filter(entry => {
            const name = normalized(entry.name);
            return name.length > 2 && (title.startsWith(name + " ") || title.startsWith(name + " -"));
        });
        if (prefixNames.length === 1)
            return prefixNames[0];
    }
    const icons = entries.filter(entry => normalized(entry.icon).replace(/-symbolic$/, "") === id);
    return icons.length === 1 ? icons[0] : null;
}

/** Match a tray entry to a dock application using shared desktop identity. */
function matchesGroup(tray, appId, desktopEntry) {
    if (!tray?.item)
        return false;
    if (tray.desktopEntry && desktopEntry)
        return normalized(tray.desktopEntry.id) === normalized(desktopEntry.id);
    const groupKeys = identifiers(appId);
    const trayId = trayIdentifier(tray.item.id);
    const trayTitle = normalized(tray.item.title);
    return groupKeys.includes(trayId) || (trayTitle.length > 0 && groupKeys.includes(trayTitle));
}

/** Deduplicate GTK GAction entries, preferring application-level object paths. */
function parseGtkActions(output) {
    let parsed = [];
    try {
        parsed = JSON.parse(output);
    } catch (error) {
        return [];
    }
    if (!Array.isArray(parsed))
        return [];
    const byAction = new Map();
    for (const item of parsed) {
        const id = String(item?.action ?? "");
        const title = String(item?.title ?? "").trim();
        if (id.length === 0 || title.length === 0 || id === "new-window" || /^new\s+window$/i.test(title))
            continue;
        const isAppPath = !String(item?.path ?? "").includes("/window/");
        if (!byAction.has(id) || isAppPath)
            byAction.set(id, { title, service: String(item.service ?? ""), path: String(item.path ?? ""), action: id });
    }
    return Array.from(byAction.values());
}
