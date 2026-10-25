# Quickshell Agent Guide

Quickshell QML shell & backend daemon for NixOS (`laptop`, `pc`).
RULE: Must stay under 50 lines. Keep this file updated on any architectural change.

## Architecture
- `config/minimal/`: QML shell. Entry: `shell.qml` (`ShellRoot`).
- `config/minimal/modules/`: Subsystems (`bar`, `topleft`, `topright`, `launcher`, `dock`, `workspaceView`, `power`, `network`, `frame`).
- `home-manager.nix` & `configuration.nix`: Package, service & Config singleton generation.
- Python helpers: `network_control.py` (NM CLI/JSON), `qt-menu.py` & `gtk-actions.py` (D-Bus menu).
- `frame/PanelSurface.qml`: translucent glass surfaces with layered borders and highlights for the bar and popups.
- `frame/PulloutPanel.qml`: shared surfaces, Escape/outside-click dismissal and delayed hover-off closing; Wi-Fi editing suppresses hover dismissal.
- `topright/BatteryService.qml`: shared UPower/sysfs state; network traffic sampling follows open network views.
- `dock/DockItems.qml` merges open/pinned apps with tray entries using desktop identity in `dock/tray-apps.js`; `bar/Tray.qml` owns tray menus.
- App-menu subprocesses live in `bar/AppMenuBackend.qml`; action normalization and calendar calculations live in adjacent JS helpers.
- Calendar views separate month navigation (`CalendarMonthGrid`) from plain agenda day/event rows; empty dates appear only when selected.
- Launcher ranking lives in `launcher/search.js`; `EmojiData.qml` loads `emoji.json` on demand; results use `ListView`.
- Logic checks: `node tests/ui-logic.test.cjs` and `python3 -B -m unittest network_control_test.py`.

## Conventions & Rules
- Header: Always include `pragma ComponentBehavior: Bound` at file top.
- Size limit: Files must stay under 250 LOC; functions under 50 LOC.
- Theme: Never hardcode hex colors or arbitrary px sizes; use `Theme.<token>`.
- Scope qualification: Always use `root.<prop>` to avoid scope shadowing.
- UI/UX: Interactive elements must have `PointingHandCursor`, hover transitions, and keyboard focus/Escape handling.
- Timers: Avoid unconditional polling; gate `running` by `visible` or user interactions.
- Python: Never leave stdin unclosed on `--password-stdin`; sanitize nmcli parsing.
