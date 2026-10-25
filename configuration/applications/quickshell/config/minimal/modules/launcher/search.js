/** Deterministic launcher matching and application-name ranking. */

/** Prefer exact names, prefixes, then name substrings over metadata. */
function rank(item, query) {
    const title = item.title.toLowerCase();
    if (title === query)
        return 0;
    if (title.startsWith(query))
        return 1;
    return title.includes(query) ? 2 : 3;
}

/** Filter all query words, rank applications, then limit rendered results. */
function filterItems(items, text, rankApplications) {
    const query = text.trim().toLowerCase();
    if (!query)
        return items.slice(0, 80);
    const tokens = query.split(/\s+/);
    const matches = items.filter(item => {
        const text = (item.search ?? `${item.title} ${item.subtitle}`).toLowerCase();
        return tokens.every(token => text.includes(token));
    });
    if (rankApplications)
        matches.sort((a, b) => rank(a, query) - rank(b, query) || a.title.localeCompare(b.title));
    return matches.slice(0, 80);
}
