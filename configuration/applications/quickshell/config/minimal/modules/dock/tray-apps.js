/** Normalize application identifiers without guessing app-specific aliases. */
function normalized(value) {
    return String(value || "").toLowerCase().replace(/\.desktop$/, "");
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
    const id = trayIdentifier(item.id);
    const matches = entries.filter(entry => {
        const keys = identifiers(entry.id).concat(identifiers(entry.startupClass));
        return keys.includes(id);
    });
    if (matches.length === 1)
        return matches[0];
    if (matches.length > 1)
        return null;
    const title = normalized(item.title);
    const names = entries.filter(entry => title && normalized(entry.name) === title);
    if (names.length === 1)
        return names[0];
    if (names.length > 1)
        return null;
    const icons = entries.filter(entry => normalized(entry.icon).replace(/-symbolic$/, "") === id);
    return icons.length === 1 ? icons[0] : null;
}

/** Match a tray entry to a dock application using shared desktop identity. */
function matchesGroup(tray, appId, desktopEntry) {
    if (tray.desktopEntry && desktopEntry)
        return normalized(tray.desktopEntry.id) === normalized(desktopEntry.id);
    return trayIdentifier(tray.item.id) === normalized(appId);
}
