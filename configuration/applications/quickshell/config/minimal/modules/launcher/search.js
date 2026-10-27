/** Deterministic launcher matching with relevance and decaying launch history. */

/** Give launch history a seven-day half-life, without penalizing clock changes. */
function usageScore(record, now) {
    if (!record)
        return 0;
    const age = Math.max(0, now - record.lastUsed);
    return record.score * Math.pow(0.5, age / (7 * 86400000));
}

/** Add a launch after decaying earlier launches to the same point in time. */
function recordLaunch(history, id, now) {
    return Object.assign({}, history, {
        [id]: { score: usageScore(history[id], now) + 1, lastUsed: now }
    });
}

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
function filterItems(items, text, rankApplications, history = {}, now = Date.now()) {
    const query = text.trim().toLowerCase();
    const tokens = query ? query.split(/\s+/) : [];
    const matches = items.filter(item => {
        const text = (item.search ?? `${item.title} ${item.subtitle}`).toLowerCase();
        return tokens.every(token => text.includes(token));
    });
    if (rankApplications)
        matches.sort((a, b) => (query ? rank(a, query) - rank(b, query) : 0)
            || usageScore(history[b.id], now) - usageScore(history[a.id], now)
            || a.title.localeCompare(b.title));
    return matches.slice(0, 80);
}
