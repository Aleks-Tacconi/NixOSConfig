/** Build calendar agenda data independently of its visual layout. */

/** Group events into all days of the visible month. */
function buildScheduleDays(eventsList, monthDate, now) {
    const dayMap = {};
    const todayStr = Qt.formatDateTime(now, "yyyy-MM-dd");
    const year = monthDate.getFullYear();
    const month = monthDate.getMonth();
    const numDays = new Date(year, month + 1, 0).getDate();
    const viewPrefix = Qt.formatDateTime(monthDate, "yyyy-MM");

    for (let d = 1; d <= numDays; ++d) {
        const dayKey = `${viewPrefix}-${String(d).padStart(2, "0")}`;
        dayMap[dayKey] = [];
    }

    if (eventsList && eventsList.length > 0) {
        for (let i = 0; i < eventsList.length; ++i) {
            const ev = eventsList[i];
            if (!ev || !ev.date)
                continue;

            if (ev.date.startsWith(viewPrefix)) {
                if (!dayMap[ev.date])
                    dayMap[ev.date] = [];
                dayMap[ev.date].push(ev);
            }
        }
    }

    const sortedKeys = Object.keys(dayMap).sort();
    const result = [];

    for (const key of sortedKeys) {
        const day = scheduleDay(key, dayMap[key], todayStr, now);
        if (day !== null)
            result.push(day);
    }

    return result;
}


/** Sort a day and place its current-time marker. */
function scheduleDay(key, events, todayStr, now) {
    const parts = key.split("-");
    if (parts.length < 3)
        return null;

    const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
    const isToday = key === todayStr;
    const evs = events.slice();

    evs.sort((a, b) => {
        if (!a.startTime && b.startTime) return -1;
        if (a.startTime && !b.startTime) return 1;
        return (a.startTime || "").localeCompare(b.startTime || "");
    });

    let nowInsertIndex = 0;
    if (isToday) {
        for (let e = 0; e < evs.length; ++e) {
            if (evs[e].endAt && evs[e].endAt < now)
                nowInsertIndex = e + 1;
        }
    }

    return {
        dateKey: key,
        date: date,
        isToday: isToday,
        formattedHeader: Qt.formatDateTime(date, "ddd, d MMM"),
        events: evs,
        nowInsertIndex: nowInsertIndex
    };
}

/** Hide empty days except the explicitly selected date. */
function visibleDays(days, selectedKey) {
    return days.filter(day => day.events.length > 0 || day.dateKey === selectedKey);
}
