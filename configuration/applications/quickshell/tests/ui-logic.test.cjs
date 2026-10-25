/** Exercise launcher ranking and extracted calendar/application data logic. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

/** Load a QML JavaScript helper with only the globals it needs. */
function load(relative, globals = {}) {
    const context = vm.createContext(globals);
    vm.runInContext(fs.readFileSync(path.join(__dirname, '../config/minimal/modules', relative), 'utf8'), context);
    return context;
}

/** Convert VM-owned values for cross-context comparisons. */
function plain(value) {
    return JSON.parse(JSON.stringify(value));
}

const search = load('launcher/search.js');
const actions = load('bar/app-menu-actions.js');
const calendar = load('topleft/calendar-data.js', {
    Qt: {
        /** Supply date-key formatting used by the extracted calendar code. */
        formatDateTime(date, format) {
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            return format === 'yyyy-MM' ? `${date.getFullYear()}-${month}` : `${date.getFullYear()}-${month}-${day}`;
        }
    }
});

test('application names rank ahead of metadata, regardless of source order', () => {
    const items = [
        { title: 'Browser', search: 'browser terminal' },
        { title: 'My Terminal', search: 'my terminal' },
        { title: 'Terminal Pro', search: 'terminal pro' },
        { title: 'Terminal', search: 'terminal' }
    ];
    assert.deepEqual(plain(search.filterItems(items, ' TERMINAL ', true)).map(item => item.title),
        ['Terminal', 'Terminal Pro', 'My Terminal', 'Browser']);
    assert.equal(items[0].title, 'Browser');
});

test('clipboard results keep source order and require every search word', () => {
    const items = [
        { title: 'Recent', search: 'project alpha notes' },
        { title: 'Older', search: 'alpha project' },
        { title: 'Unrelated', search: 'project beta' }
    ];
    assert.deepEqual(plain(search.filterItems(items, 'alpha project', false)).map(item => item.title), ['Recent', 'Older']);
    assert.equal(search.filterItems(items, 'missing', false).length, 0);
});

test('ranking occurs before limiting results', () => {
    const items = Array.from({ length: 100 }, (_, index) => ({ title: `App ${index}`, search: 'terminal' }));
    items.push({ title: 'Terminal', search: 'terminal' });
    assert.equal(search.filterItems(items, 'terminal', true)[0].title, 'Terminal');
    assert.equal(search.filterItems(items, '', false).length, 80);
});

test('emoji resource preserves searchable glyph and description pairs', () => {
    const items = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/minimal/modules/launcher/emoji.json')));
    assert.ok(items.length > 1000);
    assert.ok(items.every(item => item.length === 2 && item.every(value => typeof value === 'string' && value.length > 0)));
});

test('calendar includes leap day and excludes events from other months', () => {
    const days = calendar.buildScheduleDays([{ date: '2024-03-01', title: 'Next month' }], new Date(2024, 1, 1), new Date(2024, 1, 29));
    assert.equal(days.length, 29);
    assert.equal(days[28].dateKey, '2024-02-29');
    assert.equal(days[28].isToday, true);
    assert.ok(days.every(day => day.events.length === 0));
});

test('agenda sorts all-day events first and places now after finished events', () => {
    const now = new Date(2026, 9, 24, 12);
    const events = [
        { date: '2026-10-24', title: 'Later', startTime: '14:00', endAt: new Date(2026, 9, 24, 15) },
        { date: '2026-10-24', title: 'Earlier', startTime: '09:00', endAt: new Date(2026, 9, 24, 10) },
        { date: '2026-10-24', title: 'All day', startTime: '', endAt: null }
    ];
    const today = calendar.buildScheduleDays(events, now, now)[23];
    assert.deepEqual(plain(today.events).map(event => event.title), ['All day', 'Earlier', 'Later']);
    assert.equal(today.nowInsertIndex, 2);
    assert.equal(events[0].title, 'Later');
});

test('application matching supports desktop IDs and rejects unrelated windows', () => {
    assert.equal(actions.ipcMatchesApp({ pid: 10, class: 'Firefox' }, 'org.mozilla.firefox.desktop'), true);
    assert.equal(actions.ipcMatchesApp({ pid: 10, class: 'Terminal' }, 'org.mozilla.firefox'), false);
    assert.equal(actions.ipcMatchesApp({ pid: 0, class: 'Firefox' }, 'Firefox'), false);
});

test('menu actions deduplicate desktop and GTK entries and validate payloads', () => {
    const gtk = { title: 'New Window', action: 'app.new-window', service: ':1.23', path: '/menu' };
    assert.equal(actions.combineActions([{ name: 'New Window' }], [gtk]).length, 1);
    assert.equal(actions.parseGtkActions('{broken'), null);
    assert.equal(actions.parseGtkActions(JSON.stringify([{ ...gtk, path: 'invalid' }])), null);
    assert.equal(actions.parseGtkActions(JSON.stringify([gtk])).length, 1);
});

test('agenda hides empty days but retains the selected empty date', () => {
    const days = [
        { dateKey: '2026-10-24', events: [] },
        { dateKey: '2026-10-25', events: [{ title: 'Meeting' }] },
        { dateKey: '2026-10-26', events: [] }
    ];
    assert.deepEqual(plain(calendar.visibleDays(days, '2026-10-24')).map(day => day.dateKey), ['2026-10-24', '2026-10-25']);
    assert.deepEqual(plain(calendar.visibleDays(days, '2026-10-26')).map(day => day.dateKey), ['2026-10-25', '2026-10-26']);
    assert.deepEqual(plain(calendar.visibleDays(days, '')).map(day => day.dateKey), ['2026-10-25']);
    assert.equal(calendar.visibleDays([{ dateKey: '2026-10-24', events: [] }], '').length, 0);
});

const trayApps = load('dock/tray-apps.js');

test('tray apps resolve desktop identity without application-specific aliases', () => {
    const desktop = { id: 'org.example.Player', startupClass: 'player', name: 'Media Player' };
    const entries = [desktop, { id: 'chat', name: 'Chat' }];
    assert.equal(trayApps.desktopEntryForTray({ id: 'player-1234' }, entries), desktop);
    assert.equal(trayApps.desktopEntryForTray({ id: 'player_status_icon_1' }, entries), desktop);
    assert.equal(trayApps.desktopEntryForTray({ id: 'unknown', title: 'Media Player' }, entries), desktop);
    assert.equal(trayApps.desktopEntryForTray({ id: 'unrelated' }, entries), null);
    const iconEntry = { id: 'org.example.Manager', icon: 'wireless-symbolic' };
    assert.equal(trayApps.desktopEntryForTray({ id: 'wireless' }, [iconEntry]), iconEntry);
    assert.equal(trayApps.desktopEntryForTray({ id: 'player' }, [...entries,
        { id: 'other.player', name: 'Other Player' }]), null);
    assert.equal(trayApps.matchesGroup({ item: { id: 'player-1234' }, desktopEntry: desktop },
        'player', desktop), true);
    assert.equal(trayApps.matchesGroup({ item: { id: 'chat' }, desktopEntry: entries[1] },
        'player', desktop), false);
    assert.equal(trayApps.matchesGroup({ item: { id: 'player-1234' }, desktopEntry: null },
        'PLAYER', null), true);
});
